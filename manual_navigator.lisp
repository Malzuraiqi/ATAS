
(defstruct error-code
  device
  component
  symptoms
  (failed-fixes nil))

(defparameter *troubleshooting-tree*
  '((root
     nil
     (
      ;; ===== ROUTER POWER ISSUE BRANCHES =====
      
      ((router power led_off)
       ("Check if power cable is firmly plugged into router"
        "Check if power cable is plugged into wall outlet"
        "Verify outlet has power by testing with another device")
       (
        ((router power led_off :not "check_cable")
         ("Inspect power cable for visible damage or fraying"
          "Try replacing power cable with a known working cable"
          "Test with a different wall outlet"
          "Check if circuit breaker has tripped")
         nil)))

      ((router power no_power)
       ("Check if power cable is firmly connected to router"
        "Verify the power cable is connected to a live outlet"
        "Test outlet with a lamp or other device to confirm power")
       (
        ((router power no_power :not "check_cable")
         ("Replace power cable with a new one"
          "Try a different power outlet in another room"
          "Check for power adapter LED indicator lights"
          "Verify power adapter is not damaged or overheating")
         nil)))

      ;; ===== ROUTER CONNECTIVITY ISSUE BRANCHES =====
      
      ((router connectivity no_internet)
       ("Power cycle modem: unplug for 30 seconds"
        "Wait for modem lights to stabilize (2-3 minutes)"
        "Verify ethernet cable is connected between modem and router"
        "Restart router by power cycling")
       (
        ((router connectivity no_internet :not "restart_router")
         ("Check modem status lights: all should be green"
          "Log into router admin panel (192.168.1.1)"
          "Verify WAN/Internet settings are correct"
          "Check for ISP outages in your area"
          "Restart modem completely")
         nil)))

      ((router connectivity wifi_no_connection)
       ("Check if WiFi is enabled on router (look for LED)"
        "Move closer to router to test signal strength"
        "Restart router by unplugging for 30 seconds"
        "Check WiFi password for typos when reconnecting")
       (
        ((router connectivity wifi_no_connection :not "check_wifi_settings")
         ("Log into router (192.168.1.1 or admin panel)"
          "Check if WiFi broadcasting is enabled in settings"
          "Verify correct WiFi name (SSID) is displayed"
          "Restart WiFi from router settings"
          "Factory reset router as last resort")
         nil)))

      ;; ===== ROUTER INTERNAL ISSUE BRANCHES =====
      
      ((router internal overheating)
       ("Check for dust or blockage around router vents"
        "Ensure router has at least 1 inch clearance on all sides"
        "Move router away from direct sunlight or heat sources"
        "Place router in a well-ventilated area")
       nil)

      ((router internal low_performance)
       ("Check how many devices are connected to WiFi"
        "Move closer to router for better signal"
        "Restart router to clear memory"
        "Check for interference from other WiFi networks")
       (
        ((router internal low_performance :not "update_firmware")
         ("Check for router firmware updates in settings"
          "Download and install latest firmware version"
          "Wait for update to complete (do not power off)"
          "Restart router after firmware update"
          "Check for ongoing background downloads or updates")
         nil)))

      ;; ===== PRINTER POWER ISSUE BRANCHES =====
      
      ((printer power no_power)
       ("Check if power cable is firmly connected to printer"
        "Verify power cable is plugged into a live outlet"
        "Test outlet by plugging in a lamp or other device")
       (
        ((printer power no_power :not "check_power_cable")
         ("Try a different power outlet"
          "Inspect power cable for damage"
          "Replace power cable with a known working cable"
          "Check power button - press and hold for 3 seconds"
          "Leave printer unplugged for 1 minute, then reconnect")
         nil)))

      ((printer power led_off)
       ("Verify power cable is connected to both printer and outlet"
        "Check that outlet has power"
        "Look for power button and press it"
        "Wait 30 seconds for power lights to appear")
       nil)

      ;; ===== PRINTER CONNECTIVITY ISSUE BRANCHES =====
      
      ((printer connectivity not_printing)
       ("Check that printer power is on and ready"
        "Verify printer shows online/ready status"
        "Ensure print driver is installed on computer"
        "Check Windows print queue for stuck jobs")
       (
        ((printer connectivity not_printing :not "reinstall_driver")
         ("Remove printer from devices"
          "Download latest printer driver from manufacturer website"
          "Install driver and restart computer"
          "Add printer back to system"
          "Test print with simple text document")
         nil)))

      ((printer connectivity paper_jam)
       ("Turn off printer completely"
        "Open all access panels and covers"
        "Look for jammed paper in paper path"
        "Gently remove any paper stuck in rollers")
       nil)

      ;; ===== PRINTER INTERNAL ISSUE BRANCHES =====
      
      ((printer internal paper_jam)
       ("Open printer access panels"
        "Locate jammed paper in the feed path"
        "Gently pull paper out in direction of feed"
        "Close all panels and test with blank page"
        "Clear any paper fragments from rollers")
       nil)

      ((printer internal print_quality_poor)
       ("Check ink cartridge levels in printer menu"
        "Clean print nozzles using printer utility"
        "Run printer maintenance cycle if available"
        "Check if paper type matches printer settings")
       (
        ((printer internal print_quality_poor :not "replace_ink")
         ("Replace ink cartridges with fresh ones"
          "Align print heads using printer utility"
          "Clean print heads thoroughly"
          "Use recommended paper type for best quality"
          "Check for mechanical wear in print mechanisms")
         nil)))

      ((printer internal overheating)
       ("Turn off printer and let cool for 15-20 minutes"
        "Check for dust or debris inside printer"
        "Ensure printer has adequate ventilation"
        "Verify room temperature is within normal range")
       nil)

      ((printer internal low_performance)
       ("Check available paper in input tray"
        "Wait for any ongoing print jobs to complete"
        "Clear print queue on computer"
        "Restart printer and computer")
       (
        ((printer internal low_performance :not "update_printer_firmware")
         ("Check printer menu for firmware update option"
          "Download latest firmware from manufacturer"
          "Connect printer to network for update"
          "Install firmware following manufacturer instructions"
          "Restart printer and test print speed")
         nil)))
      ))))

(defun condition-matches-p (condition error-code)
  "Check if a condition matches the error code"
  (let ((cond-device (first condition))
        (cond-component (second condition))
        (cond-symptom (third condition))
        (not-keyword (fourth condition))
        (failed-fix (fifth condition)))
    
    (let ((device-match (eq cond-device (intern (string-upcase (error-code-device error-code)))))
          (component-match (eq cond-component (intern (string-upcase (error-code-component error-code)))))
          (symptom-match (member (string-downcase (symbol-name cond-symptom))
                                 (mapcar #'string-downcase (error-code-symptoms error-code))
                                 :test #'string=))
          (fix-match (if (eq not-keyword :not)
                        (not (member failed-fix (error-code-failed-fixes error-code) :test #'string-equal))
                        t)))

      (and device-match component-match symptom-match fix-match))))



(defun find-path (error-code &optional (tree *troubleshooting-tree*))
  "Find the shortest path of fix instructions for given error code.
   Uses recursive tree traversal.
   Returns: list of fix instruction strings"
  
  (labels ((search-tree (nodes accumulated-path depth)
             (if (null nodes)
                 nil
                 (let* ((current-node (first nodes))
                        (condition (first current-node))
                        (fixes (second current-node))
                        (children (third current-node)))

                   (if (eq condition 'root)
                       (search-tree children fixes (+ depth 1))
                       
                       (if (condition-matches-p condition error-code)
                           (let ((current-path (append accumulated-path fixes)))
                             (if children
                                 (or (search-tree children current-path (+ depth 1))
                                     current-path)
                                 current-path))
                           (search-tree (rest nodes) accumulated-path depth)))))))
    
    (search-tree tree nil 0)))



(defun print-fix-steps (steps)
  "Print fix steps to terminal"
  (format t "~%TROUBLESHOOTING INSTRUCTIONS:~%")
  (format t "================================~%~%")
  
  (if (null steps)
      (format t "No troubleshooting steps found.~%~%")
      (loop for step in steps
            for i from 1
            do (format t "~2D. ~A~%" i step)))

  (format t "~%"))

(defun test-router-power ()
  (let ((error (make-error-code
                :device "router"
                :component "power"
                :symptoms '("led_off" "no_power"))))
    (format t "~%TEST: Router Power Issue~%")
    (print-fix-steps (find-path error))))

(defun test-router-connectivity ()
  (let ((error (make-error-code
                :device "router"
                :component "connectivity"
                :symptoms '("no_internet"))))
    (format t "~%TEST: Router No Internet~%")
    (print-fix-steps (find-path error))))

(defun test-printer-jam ()
  (let ((error (make-error-code
                :device "printer"
                :component "internal"
                :symptoms '("paper_jam"))))
    (format t "~%TEST: Printer Paper Jam~%")
    (print-fix-steps (find-path error))))

#+sbcl
(when (member "--run-tests" sb-ext:*posix-argv* :test #'string=)
  (test-router-power)
  (test-router-connectivity)
  (test-printer-jam))
