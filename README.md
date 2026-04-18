# Autonomous Device Troubleshooting Assistant (ATAS)

## Overview

The Autonomous Device Troubleshooting Assistant (ATAS) is a multi-paradigm intelligent system designed to help users diagnose and resolve common hardware issues in devices such as routers and printers.

The system combines three programming paradigms within a single architecture:
- Object-Oriented Programming (Python): models hardware devices and their components
- Logic Programming (Prolog): performs root-cause diagnosis using rule-based inference
- Functional Programming (Lisp): generates step-by-step troubleshooting instructions using recursive tree traversal

A Flask-based web interface is used to interact with the system and provide a chatbot-style troubleshooting experience.

---

## System Architecture

The system is divided into four main components:

- **Frontend (Flask + HTML/JS)**  
  Provides a simple chat interface for users to select devices, symptoms, and receive troubleshooting steps.

- **OOP Layer (hardware_model.py)**  
  Represents devices, components, and system state using classes and structured objects.

- **Logic Layer (knowledge_base.pl)**  
  Uses Prolog rules and backtracking to identify the most likely root cause of a problem.

- **Functional Layer (manual_navigator.lisp)**  
  Uses recursive traversal to generate structured troubleshooting steps based on the diagnosed fault.

- **Bridge Layer (bridge.py)**  
  Connects Python with Prolog and Lisp by handling subprocess communication and data exchange.

---

## Key Features

- Rule-based fault diagnosis using Prolog
- Step-by-step troubleshooting using Lisp recursion
- Session-based chatbot with attempt tracking
- Backtracking mechanism for alternative solutions
- Multi-device support (router, printer)
- No external AI dependencies (fully rule-based system)

---

## Project Structure

- app.py — Main Flask application and API logic  
- bridge.py — Communication layer between Python, Prolog, and Lisp  
- hardware_model.py — Object-oriented device and error modeling  
- knowledge_base.pl — Prolog rules for fault diagnosis  
- manual_navigator.lisp — Lisp-based troubleshooting tree  
- templates/ — Web interface  

---

## Setup Instructions

1. Install SWI-Prolog  
2. Install SBCL  
3. Create and activate a Python virtual environment  
4. Install required Python dependencies using requirements.txt  
5. Run the Flask application and open the local server in a browser  

---

## Authors

- Omar Abdelnaby  
- Zaid Irsheid  
- Mohammed Hesham  
- Yousef Abuhantash  
