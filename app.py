"""
Web-based Autonomous Device Troubleshooting Assistant (ATAS)
Flask backend with Prolog and Lisp rule-based troubleshooting.
Session-based chatbot with unlimited usage and attempt tracking.
"""

import concurrent.futures
import uuid
from datetime import datetime, timedelta
from flask import Flask, render_template, request, jsonify, session
from hardware_model import ErrorCode
from bridge import call_prolog, call_lisp, get_fix_identifier

app = Flask(__name__)
app.secret_key = "ofjsipfjiw402342423sdd232"
app.config['SESSION_TIMEOUT'] = timedelta(hours=1)
prolog_executor = concurrent.futures.ThreadPoolExecutor(max_workers=2)

# Session storage for managing attempt counters
sessions = {}

SYMPTOM_OPTIONS = {
    ("router", "power"): [
        {"id": "led_off", "text": "LED light is completely off"},
        {"id": "no_power", "text": "No power at all"}
    ],
    ("router", "connectivity"): [
        {"id": "no_internet", "text": "No internet connection"},
        {"id": "wifi_no_connection", "text": "WiFi not showing up"}
    ],
    ("router", "internal"): [
        {"id": "overheating", "text": "Router is overheating"},
        {"id": "low_performance", "text": "Performance is very slow"}
    ],
    ("printer", "power"): [
        {"id": "no_power", "text": "Printer won't turn on"},
        {"id": "led_off", "text": "LED light is off"}
    ],
    ("printer", "connectivity"): [
        {"id": "not_printing", "text": "Printer showing as offline"}
    ],
    ("printer", "internal"): [
        {"id": "paper_jam", "text": "Paper jam detected"},
        {"id": "print_quality_poor", "text": "Print quality is poor"},
        {"id": "overheating", "text": "Printer is overheating"},
        {"id": "low_performance", "text": "Printer is responding very slowly"}
    ],
}

class ATASSession:
    """Manages a user session with attempt tracking and fault tracking."""
    def __init__(self, session_id):
        self.session_id = session_id
        self.query_count = 0
        self.created_at = datetime.now()
        self.current_error_code = None
        self.chat_history = []
        self.attempted_faults = []

    def increment_query(self):
        """Increment the attempt counter for each diagnosis step."""
        self.query_count += 1

    def add_attempted_fault(self, fault):
        """Track attempted fault to prevent infinite loops."""
        if fault not in self.attempted_faults:
            self.attempted_faults.append(fault)

    def is_fault_repeated(self, fault):
        """Check if fault was already attempted."""
        return fault in self.attempted_faults

    def reset(self):
        self.query_count = 0
        self.current_error_code = None
        self.chat_history = []
        self.attempted_faults = []


@app.before_request
def init_session():
    """Initialize or retrieve session."""
    if 'atas_session_id' not in session:
        session_id = str(uuid.uuid4())
        session['atas_session_id'] = session_id
        sessions[session_id] = ATASSession(session_id)


def get_user_session():
    """Get the current user's ATAS session. Create if doesn't exist."""
    session_id = session.get('atas_session_id')
    
    # If no session_id in Flask session, create one
    if not session_id:
        session_id = str(uuid.uuid4())
        session['atas_session_id'] = session_id
    
    # If session_id not in sessions dict, create it
    if session_id not in sessions:
        sessions[session_id] = ATASSession(session_id)
    
    return sessions[session_id]


@app.route('/')
def index():
    """Serve the main chat interface."""
    return render_template('index.html')


@app.route('/api/symptom-options', methods=['POST'])
def get_symptom_options():
    """Return available symptoms for selected device and component."""
    data = request.get_json(silent=True) or {}
    device = data.get('device')
    component = data.get('component')
    
    key = (device, component)
    options = SYMPTOM_OPTIONS.get(key, [])
    
    return jsonify({'options': options})


@app.route('/api/diagnose', methods=['POST'])
def diagnose():
    """
    Main troubleshooting endpoint.
    Takes device, component, symptoms → returns Prolog diagnosis + Lisp steps.
    """
    atas_session = get_user_session()
    
    data = request.get_json(silent=True) or {}
    device = data.get('device', '').lower()
    component = data.get('component', '').lower()
    symptoms = data.get('symptoms', [])
    
    if not device or not component or not symptoms:
        return jsonify({'error': 'Missing device, component, or symptoms'}), 400

    atas_session.increment_query()
    
    # Create ErrorCode object
    ec = ErrorCode(
        device=device,
        component=component,
        symptoms=symptoms,
        failed_fixes=[]
    )
    atas_session.current_error_code = ec
    
    future = prolog_executor.submit(call_prolog, ec)
    fix_steps = call_lisp(ec)
    fault = future.result(timeout=15)
    diagnosis_result = None
    
    if fault.lower() == "unknown_issue" or not fault:
        # No diagnosis available - direct to service center
        diagnosis_result = "Unable to diagnose. Please visit a service center for further assistance."
        fault = "unknown_issue"
        fix_steps = []
    else:
        diagnosis_result = fault.replace("_", " ").title()
    
    # Track this fault as attempted
    atas_session.add_attempted_fault(fault)
    
    response = {
        'diagnosis': diagnosis_result,
        'fault': fault,
        'fix_steps': fix_steps,
        'final': fault == "unknown_issue",
        'queries_used': atas_session.query_count,
        'failed_fixes': ec.failed_fixes
    }
    
    return jsonify(response)


@app.route('/api/feedback', methods=['POST'])
def provide_feedback():
    """
    Handles user feedback (worked/didn't work).
    - If worked=true: Just acknowledge success
    - If worked=false: Try next solution by getting new fault with updated failed_fixes
    """
    atas_session = get_user_session()
    data = request.get_json(silent=True) or {}
    worked = data.get('worked', False)
    
    if not atas_session.current_error_code:
        return jsonify({'error': 'No active diagnosis'}), 400
    
    if not worked:
        # Mark this fix as failed and prepare for next diagnosis
        ec = atas_session.current_error_code
        fault = data.get('fault', '')
        
        # Add current fault to failed_fixes if it's not already there
        if fault:
            fix_id = get_fix_identifier(fault)
            if fix_id not in ec.failed_fixes:
                ec.failed_fixes.append(fix_id)
        
        # Increment query for next attempt
        atas_session.increment_query()
        
        future = prolog_executor.submit(call_prolog, ec)
        fix_steps = call_lisp(ec)
        next_fault = future.result(timeout=15)
        
        # Check for termination conditions
        should_terminate = False
        diagnosis_result = None
        
        # Condition 1: No new faults available (unknown_issue)
        if next_fault.lower() == "unknown_issue" or not next_fault:
            should_terminate = True
            diagnosis_result = "All troubleshooting steps have been exhausted. Please visit a service center for further assistance."
            next_fault = "unknown_issue"
        
        # Condition 2: Repeated fault detected
        elif atas_session.is_fault_repeated(next_fault):
            should_terminate = True
            diagnosis_result = "All troubleshooting steps have been exhausted. Please visit a service center for further assistance."
            next_fault = "unknown_issue"
        
        # If no termination condition, get new steps
        if not should_terminate:
            diagnosis_result = next_fault.replace("_", " ").title()
            # Track new fault
            atas_session.add_attempted_fault(next_fault)
        else:
            fix_steps = []
        
        response = {
            'status': 'retry',
            'final': should_terminate,
            'message': diagnosis_result if should_terminate else '',
            'diagnosis': diagnosis_result,
            'fault': next_fault,
            'fix_steps': fix_steps,
            'queries_used': atas_session.query_count,
            'failed_fixes': ec.failed_fixes,
            'attempted_faults': atas_session.attempted_faults
        }
        
        return jsonify(response)
    else:
        # Issue resolved
        return jsonify({'status': 'success', 'message': 'Issue resolved successfully'})


@app.route('/api/reset-session', methods=['POST'])
def reset_session_endpoint():
    """Reset the user's session (clears query counter and history)."""
    atas_session = get_user_session()
    if atas_session:
        atas_session.reset()
    
    return jsonify({
        'status': 'reset',
        'queries_used': atas_session.query_count
    })


@app.route('/api/session-info', methods=['GET'])
def session_info():
    """Return current session status."""
    atas_session = get_user_session()
    if not atas_session:
        return jsonify({'error': 'No active session'}), 404
    
    return jsonify({
        'queries_used': atas_session.query_count,
        'attempted_faults': atas_session.attempted_faults
    })


@app.errorhandler(404)
def not_found(e):
    return jsonify({'error': 'Not found'}), 404


@app.errorhandler(500)
def internal_error(e):
    return jsonify({'error': 'Internal server error'}), 500


if __name__ == '__main__':
    app.run(debug=True, host='127.0.0.1', port=5000)
