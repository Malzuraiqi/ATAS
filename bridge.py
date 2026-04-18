# bridge.py
# Handles all subprocess communication with Lisp and Prolog modules.

import subprocess
import re
from hardware_model import ErrorCode
import os

BASE_DIR    = os.path.dirname(os.path.abspath(__file__))
LISP_FILE   = os.path.join(BASE_DIR, "manual_navigator.lisp")
PROLOG_FILE = os.path.join(BASE_DIR, "knowledge_base.pl")


FAULT_TO_FIX = {
    # Router Power
    "power_cable_issue":            "check_cable",
    "outlet_issue":                 "check_outlet",
    "power_adapter_issue":          "replace_adapter",
    "power_supply_issue":           "replace_power_supply",
    
    # Router Connectivity
    "router_needs_restart":         "restart_router",
    "modem_issue":                  "check_modem",
    "ethernet_cable_issue":         "check_ethernet",
    "dns_issue":                    "check_dns",
    "ip_conflict":                  "reset_ip",
    "wifi_config_issue":            "check_wifi_settings",
    "isp_outage":                   "contact_isp",
    
    # Router Internal
    "overheating_issue":            "improve_ventilation",
    "firmware_issue":               "update_firmware",
    "memory_issue":                 "clear_cache",
    "hardware_issue":               "replace_device",
    
    # Printer Power
    "printer_power_cable_issue":    "check_power_cable",
    "printer_outlet_issue":         "check_power_outlet",
    "printer_power_button_issue":   "check_power_button",
    "printer_power_supply_issue":   "replace_printer_power_supply",
    
    # Printer Connectivity
    "printer_driver_issue":         "reinstall_driver",
    "printer_usb_issue":            "check_usb",
    "printer_network_issue":        "check_network",
    "printer_spooler_issue":        "clear_spooler",
    
    # Printer Internal
    "paper_jam_issue":              "clear_paper_path",
    "print_quality_issue":          "replace_ink",
    "printhead_issue":              "clean_printhead",
    "printer_overheating_issue":    "improve_printer_ventilation",
    "printer_firmware_issue":       "update_printer_firmware",
    "printer_hardware_failure":     "replace_printer_hardware",
}

def call_lisp(ec: ErrorCode):
    """
    Calls the Lisp module to get troubleshooting steps for the given error code.
    Uses SBCL to run the manual_navigator.lisp script, passing the error code details as arguments.
    """
    symptoms_lisp = " ".join(f'"{s}"' for s in ec.symptoms) if ec.symptoms else ""
    failed_fixes_lisp = " ".join(f'"{f}"' for f in ec.failed_fixes) if ec.failed_fixes else ""

    script = (
        f'(let ((ec (make-error-code '
        f':device "{ec.device}" '
        f':component "{ec.component}" '
        f':symptoms (list {symptoms_lisp}) '
        f':failed-fixes (list {failed_fixes_lisp})))) '
        f'(print-fix-steps (find-path ec)))'
    )

    try:
        result = subprocess.run(
            ["sbcl", "--noinform", "--disable-debugger", "--non-interactive", "--load", LISP_FILE, "--eval", script, "--eval", "(sb-ext:quit)"],
            capture_output=True, text=True, timeout=15
        )
        if result.stderr.strip():
            print(f"[bridge] Lisp stderr: {result.stderr.strip()}")
        if result.returncode != 0:
            return []
        steps = _parse_lisp_output(result.stdout)
        if not ec.failed_fixes:
            steps = steps[:4]
        return steps
    except FileNotFoundError:
        print("[bridge] SBCL not found. Is Common Lisp installed?")
        return []
    except subprocess.TimeoutExpired:
        print("[bridge] Lisp call timed out.")
        return []


def call_prolog(ec: ErrorCode):
    """
    Calls the Prolog module to diagnose the root cause fault for the given error code.
    Uses SWI-Prolog to consult the knowledge base and query for the fault.
    """
    symptoms_pl    = "[" + ",".join(ec.symptoms)    + "]"
    failed_fixes_pl = "[" + ",".join(ec.failed_fixes) + "]"

    query = (
        f"consult('{PROLOG_FILE.replace(os.sep, '/')}'), "
        f"diagnose({ec.device},{ec.component},"
        f"{symptoms_pl},{failed_fixes_pl},Fault), "
        f"write(Fault), nl, halt."
    )
    
    try:
        result = subprocess.run(
            ["swipl", "-g", query],
            capture_output=True, text=True, timeout=15
        )
        if result.stderr.strip():
            print(f"[bridge] Prolog stderr: {result.stderr.strip()}")
        if result.returncode != 0:
            return ""
        return result.stdout.strip()
    except FileNotFoundError:
        print("[bridge] SWI-Prolog not found. Is swipl installed?")
        return ""
    except subprocess.TimeoutExpired:
        print("[bridge] Prolog call timed out.")
        return ""


def get_fix_identifier(fault):
    """
    Maps a Prolog fault name to the fix identifier used in failed_fixes.
    This identifier is added to ec.failed_fixes when a fix attempt fails.
    """
    return FAULT_TO_FIX.get(fault, fault)


def _parse_lisp_output(raw):
    """
    Parses the output from the Lisp subprocess.
    Strips headers and extracts the numbered step lines into a list of strings.
    """
    steps = []
    for line in raw.splitlines():
        match = re.match(r'^\s*\d+\.\s+(.+)$', line)
        if match:
            steps.append(match.group(1).strip())
    return steps
