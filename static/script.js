const deviceSelect = document.getElementById("device");
const componentSelect = document.getElementById("component");
const symptomList = document.getElementById("symptom-list");
const diagnosisForm = document.getElementById("diagnosis-form");
const diagnoseBtn = document.getElementById("diagnose-btn");
const resetBtn = document.getElementById("reset-btn");
const chatLog = document.getElementById("chat-log");
const sessionPill = document.getElementById("session-pill");
const statusText = document.getElementById("status-text");
const actionPanel = document.getElementById("action-panel");

let lastDiagnosis = null;
let currentParams = null;
let isFinal = false;

async function requestJson(url, options = {}) {
    const response = await fetch(url, {
        headers: { "Content-Type": "application/json" },
        ...options,
    });

    const data = await response.json();
    if (!response.ok) {
        throw { status: response.status, data };
    }
    return data;
}

function appendMessage(role, text, isSingleLine = false) {
    const article = document.createElement("article");
    article.className = `message ${role}`;
    if (isSingleLine) {
        article.innerHTML = `<p>${text}</p>`;
    } else {
        article.innerHTML = text;
    }
    chatLog.appendChild(article);
    chatLog.scrollTop = chatLog.scrollHeight;
}

function updateSessionDisplay(used = 0, max = null) {
    sessionPill.textContent = max == null
        ? `Attempts Used ${used}`
        : `Attempts Used ${used} / ${max}`;
}

function renderSymptoms(options) {
    symptomList.innerHTML = "";

    if (!options.length) {
        symptomList.className = "symptom-list empty-state";
        symptomList.textContent = "No symptoms available for this selection.";
        return;
    }

    symptomList.className = "symptom-list";
    options.forEach((option) => {
        const label = document.createElement("label");
        label.className = "symptom-option";
        label.innerHTML = `
            <input type="checkbox" name="symptoms" value="${option.id}">
            <span>${option.text}</span>
        `;
        symptomList.appendChild(label);
    });
}

async function loadSymptoms() {
    const device = deviceSelect.value;
    const component = componentSelect.value;

    if (!device || !component) {
        symptomList.className = "symptom-list empty-state";
        symptomList.textContent = "Select a device and component to see symptoms.";
        return;
    }

    try {
        const data = await requestJson("/api/symptom-options", {
            method: "POST",
            body: JSON.stringify({ device, component }),
        });
        renderSymptoms(data.options || []);
    } catch (error) {
        symptomList.className = "symptom-list empty-state";
        symptomList.textContent = "Please try again.";
    }
}

function formatAssistantMessage(result) {
    let html = '';
    
    // Diagnosis title
    html += `<strong>Diagnosis: ${result.fault.replace(/_/g, ' ').toUpperCase()}</strong><br><br>`;
    
    // Description
    html += `${result.diagnosis}<br><br>`;
    
    // Suggested Fix Steps (if any)
    if (result.fix_steps && result.fix_steps.length > 0) {
        html += `<strong>Suggested Fix Steps:</strong><br>`;
        html += `<ol>`;
        result.fix_steps.forEach((step) => {
            html += `<li>${step}</li>`;
        });
        html += `</ol><br>`;
    }
    
    // Show previously attempted fixes
    if (result.failed_fixes && result.failed_fixes.length > 0) {
        html += `<strong>Previously attempted solutions:</strong><br>`;
        html += `<ul style="margin-left: 20px;">`;
        result.failed_fixes.forEach((fix) => {
            html += `<li>${fix.replace(/_/g, ' ')}</li>`;
        });
        html += `</ul><br>`;
    }
    
    return html;
}

function showActionButtons(isFinal) {
    if (isFinal) {
        actionPanel.innerHTML = '';
        actionPanel.classList.add('hidden');
    } else {
        actionPanel.innerHTML = `
            <button type="button" class="success-btn" id="worked-btn">Issue Resolved</button>
            <button type="button" class="secondary-btn" id="retry-btn">Try Another Solution</button>
        `;
        actionPanel.classList.remove('hidden');
        
        // Re-attach event listeners
        document.getElementById("worked-btn").addEventListener("click", handleWorked);
        document.getElementById("retry-btn").addEventListener("click", handleRetry);
    }
}

async function loadSessionInfo() {
    try {
        const data = await requestJson("/api/session-info");
        updateSessionDisplay(data.queries_used, data.queries_max);
    } catch (error) {
        updateSessionDisplay(0, null);
    }
}

deviceSelect.addEventListener("change", loadSymptoms);
componentSelect.addEventListener("change", loadSymptoms);

diagnosisForm.addEventListener("submit", async (event) => {
    event.preventDefault();

    const symptoms = Array.from(document.querySelectorAll('input[name="symptoms"]:checked'))
        .map((input) => input.value);

    if (symptoms.length === 0) {
        appendMessage("assistant", "Please select at least one symptom.", true);
        return;
    }

    const payload = {
        device: deviceSelect.value,
        component: componentSelect.value,
        symptoms,
    };

    currentParams = payload;
    isFinal = false;

    // Show user message
    const userMsg = `Diagnose: ${payload.device} - ${payload.component} - ${symptoms.join(', ')}`;
    appendMessage("user", userMsg, true);

    diagnoseBtn.disabled = true;
    statusText.textContent = "Diagnosing";

    try {
        const result = await requestJson("/api/diagnose", {
            method: "POST",
            body: JSON.stringify(payload),
        });

        lastDiagnosis = result;
        isFinal = result.final || false;
        
        // Show assistant message with inline steps
        appendMessage("assistant", formatAssistantMessage(result));
        
        showActionButtons(isFinal);
        
    } catch (error) {
        const message = error.data?.error || "Diagnosis failed.";
        appendMessage("assistant", message, true);
    } finally {
        diagnoseBtn.disabled = false;
        statusText.textContent = "Ready";
        await loadSessionInfo();
    }
});

async function handleWorked(event) {
    if (!lastDiagnosis) {
        return;
    }

    if (event?.currentTarget) {
        event.currentTarget.disabled = true;
    }

    appendMessage("user", "Issue resolved", true);

    try {
        await requestJson("/api/feedback", {
            method: "POST",
            body: JSON.stringify({ worked: true, fault: lastDiagnosis.fault }),
        });
        lastDiagnosis = null;
        currentParams = null;
        isFinal = true;
        actionPanel.classList.add('hidden');
        appendMessage("assistant", "Great! Your issue has been resolved. You can start a new diagnosis anytime.", true);
    } catch (error) {
        appendMessage("assistant", error.data?.error || "Could not save feedback.", true);
        if (event?.currentTarget) {
            event.currentTarget.disabled = false;
        }
    }
}

async function handleRetry(event) {
    if (!lastDiagnosis || !currentParams) {
        return;
    }

    appendMessage("user", "Try another solution", true);

    const retryButton = event?.currentTarget || document.getElementById("retry-btn");
    if (retryButton) {
        retryButton.disabled = true;
    }
    statusText.textContent = "Trying next solution...";

    try {
        const feedbackData = await requestJson("/api/feedback", {
            method: "POST",
            body: JSON.stringify({ worked: false, fault: lastDiagnosis.fault }),
        });

        lastDiagnosis = feedbackData;
        isFinal = feedbackData.final || false;
        
        // If this is the final diagnosis, show terminal message only
        if (isFinal) {
            actionPanel.classList.add('hidden');
            appendMessage("assistant", feedbackData.message || "All troubleshooting steps have been exhausted. Please visit a service center for further assistance.", true);
        } else {
            // Show assistant message with inline steps
            if (feedbackData.diagnosis && feedbackData.fix_steps) {
                appendMessage("assistant", formatAssistantMessage(feedbackData));
                showActionButtons(false);
            } else {
                appendMessage("assistant", "Unable to get next solution. Please try again.", true);
            }
        }
        
        await loadSessionInfo();
    } catch (error) {
        console.error("Error in handleRetry:", error);
        const errorMsg = error.data?.error || "Could not retrieve next solution.";
        appendMessage("assistant", errorMsg, true);
        if (retryButton) {
            retryButton.disabled = false;
        }
    } finally {
        statusText.textContent = "Ready";
    }
}

resetBtn.addEventListener("click", async () => {
    try {
        await requestJson("/api/reset-session", { method: "POST", body: JSON.stringify({}) });
        lastDiagnosis = null;
        currentParams = null;
        isFinal = false;
        actionPanel.classList.add('hidden');
        
        // Clear all chat messages
        chatLog.innerHTML = '';
        
        // Add fresh welcome message
        appendMessage("assistant", "Welcome to ATAS. Select your device details on the left, and I'll help diagnose the issue.", true);
        
        // Reset form
        deviceSelect.value = "";
        componentSelect.value = "";
        symptomList.innerHTML = "";
        
        updateSessionDisplay(0, null);
    } catch (error) {
        appendMessage("assistant", error.data?.error || "Could not reset session.", true);
    }
});

loadSessionInfo();
