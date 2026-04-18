% Knowledge base for diagnosing device faults.
% diagnose(Device, Component, Symptoms, FailedFixes, Fault).

% ===== ROUTER POWER RULES (Ordered: Simple → Advanced) =====

diagnose(router, power, Symptoms, FailedFixes, power_cable_issue) :-
    (member(led_off, Symptoms); member(no_power, Symptoms)),
    \+ member(check_cable, FailedFixes).

diagnose(router, power, Symptoms, FailedFixes, outlet_issue) :-
    (member(led_off, Symptoms); member(no_power, Symptoms)),
    member(check_cable, FailedFixes),
    \+ member(check_outlet, FailedFixes).

diagnose(router, power, Symptoms, FailedFixes, power_adapter_issue) :-
    (member(led_off, Symptoms); member(no_power, Symptoms)),
    member(check_cable, FailedFixes),
    member(check_outlet, FailedFixes),
    \+ member(replace_adapter, FailedFixes).

diagnose(router, power, Symptoms, FailedFixes, power_supply_issue) :-
    (member(led_off, Symptoms); member(no_power, Symptoms)),
    member(check_cable, FailedFixes),
    member(check_outlet, FailedFixes),
    member(replace_adapter, FailedFixes),
    \+ member(replace_power_supply, FailedFixes).

diagnose(router, power, Symptoms, FailedFixes, power_button_failure) :-
    (member(led_off, Symptoms); member(no_power, Symptoms)),
    member(check_cable, FailedFixes),
    member(check_outlet, FailedFixes),
    member(replace_adapter, FailedFixes),
    member(replace_power_supply, FailedFixes),
    \+ member(check_power_button, FailedFixes).

diagnose(router, power, Symptoms, FailedFixes, internal_fuse_blown) :-
    (member(led_off, Symptoms); member(no_power, Symptoms)),
    member(check_cable, FailedFixes),
    member(check_outlet, FailedFixes),
    member(replace_adapter, FailedFixes),
    member(replace_power_supply, FailedFixes),
    member(check_power_button, FailedFixes),
    \+ member(replace_internal_fuse, FailedFixes).

diagnose(router, power, Symptoms, FailedFixes, motherboard_power_failure) :-
    (member(led_off, Symptoms); member(no_power, Symptoms)),
    member(check_cable, FailedFixes),
    member(check_outlet, FailedFixes),
    member(replace_adapter, FailedFixes),
    member(replace_power_supply, FailedFixes),
    member(check_power_button, FailedFixes),
    member(replace_internal_fuse, FailedFixes),
    \+ member(diagnose_motherboard, FailedFixes).

diagnose(router, power, Symptoms, FailedFixes, full_hardware_failure) :-
    (member(led_off, Symptoms); member(no_power, Symptoms)),
    member(check_cable, FailedFixes),
    member(check_outlet, FailedFixes),
    member(replace_adapter, FailedFixes),
    member(replace_power_supply, FailedFixes),
    member(check_power_button, FailedFixes),
    member(replace_internal_fuse, FailedFixes),
    member(diagnose_motherboard, FailedFixes),
    \+ member(replace_full_hardware, FailedFixes).

% ===== ROUTER CONNECTIVITY RULES (Ordered: Simple → Advanced) =====

diagnose(router, connectivity, Symptoms, FailedFixes, router_needs_restart) :-
    (member(no_internet, Symptoms); member(wifi_no_connection, Symptoms)),
    \+ member(restart_router, FailedFixes).

diagnose(router, connectivity, Symptoms, FailedFixes, modem_issue) :-
    member(no_internet, Symptoms),
    member(restart_router, FailedFixes),
    \+ member(check_modem, FailedFixes).

diagnose(router, connectivity, Symptoms, FailedFixes, ethernet_cable_issue) :-
    member(no_internet, Symptoms),
    member(restart_router, FailedFixes),
    member(check_modem, FailedFixes),
    \+ member(check_ethernet, FailedFixes).

diagnose(router, connectivity, Symptoms, FailedFixes, dns_issue) :-
    member(no_internet, Symptoms),
    member(restart_router, FailedFixes),
    member(check_modem, FailedFixes),
    member(check_ethernet, FailedFixes),
    \+ member(check_dns, FailedFixes).

diagnose(router, connectivity, Symptoms, FailedFixes, ip_conflict) :-
    (member(no_internet, Symptoms); member(wifi_no_connection, Symptoms)),
    member(restart_router, FailedFixes),
    member(check_modem, FailedFixes),
    \+ member(reset_ip, FailedFixes).

diagnose(router, connectivity, Symptoms, FailedFixes, wifi_config_issue) :-
    member(wifi_no_connection, Symptoms),
    \+ member(check_wifi_settings, FailedFixes).

diagnose(router, connectivity, Symptoms, FailedFixes, isp_outage) :-
    member(no_internet, Symptoms),
    member(restart_router, FailedFixes),
    member(check_modem, FailedFixes),
    member(check_ethernet, FailedFixes),
    member(check_dns, FailedFixes),
    \+ member(contact_isp, FailedFixes).

diagnose(router, connectivity, Symptoms, FailedFixes, firmware_connectivity_issue) :-
    (member(no_internet, Symptoms); member(wifi_no_connection, Symptoms)),
    member(restart_router, FailedFixes),
    member(check_modem, FailedFixes),
    member(check_ethernet, FailedFixes),
    member(check_dns, FailedFixes),
    member(contact_isp, FailedFixes),
    \+ member(update_firmware, FailedFixes).

diagnose(router, connectivity, Symptoms, FailedFixes, wan_port_failure) :-
    member(no_internet, Symptoms),
    member(restart_router, FailedFixes),
    member(check_modem, FailedFixes),
    member(check_ethernet, FailedFixes),
    member(check_dns, FailedFixes),
    member(contact_isp, FailedFixes),
    member(update_firmware, FailedFixes),
    \+ member(check_wan_port, FailedFixes).

diagnose(router, connectivity, Symptoms, FailedFixes, router_nat_issue) :-
    member(no_internet, Symptoms),
    member(restart_router, FailedFixes),
    member(check_modem, FailedFixes),
    member(check_ethernet, FailedFixes),
    member(check_dns, FailedFixes),
    member(contact_isp, FailedFixes),
    member(update_firmware, FailedFixes),
    member(check_wan_port, FailedFixes),
    \+ member(reset_nat, FailedFixes).

diagnose(router, connectivity, Symptoms, FailedFixes, routing_table_corruption) :-
    (member(no_internet, Symptoms); member(wifi_no_connection, Symptoms)),
    member(restart_router, FailedFixes),
    member(check_modem, FailedFixes),
    member(check_ethernet, FailedFixes),
    member(check_dns, FailedFixes),
    member(contact_isp, FailedFixes),
    member(update_firmware, FailedFixes),
    member(check_wan_port, FailedFixes),
    member(reset_nat, FailedFixes),
    \+ member(rebuild_routing_table, FailedFixes).

% ===== ROUTER INTERNAL RULES (Ordered: Simple → Advanced) =====

diagnose(router, internal, Symptoms, FailedFixes, overheating_issue) :-
    member(overheating, Symptoms),
    \+ member(improve_ventilation, FailedFixes).

diagnose(router, internal, Symptoms, FailedFixes, firmware_issue) :-
    member(low_performance, Symptoms),
    \+ member(update_firmware, FailedFixes).

diagnose(router, internal, Symptoms, FailedFixes, memory_issue) :-
    member(low_performance, Symptoms),
    member(update_firmware, FailedFixes),
    \+ member(clear_cache, FailedFixes).

diagnose(router, internal, Symptoms, FailedFixes, hardware_issue) :-
    member(low_performance, Symptoms),
    member(update_firmware, FailedFixes),
    member(clear_cache, FailedFixes),
    \+ member(replace_device, FailedFixes).

diagnose(router, internal, Symptoms, FailedFixes, cpu_overload) :-
    member(low_performance, Symptoms),
    member(update_firmware, FailedFixes),
    member(clear_cache, FailedFixes),
    member(replace_device, FailedFixes),
    \+ member(reduce_cpu_load, FailedFixes).

diagnose(router, internal, Symptoms, FailedFixes, memory_leak_issue) :-
    member(low_performance, Symptoms),
    member(update_firmware, FailedFixes),
    member(clear_cache, FailedFixes),
    member(replace_device, FailedFixes),
    member(reduce_cpu_load, FailedFixes),
    \+ member(firmware_patch, FailedFixes).

diagnose(router, internal, Symptoms, FailedFixes, fan_failure) :-
    member(overheating, Symptoms),
    member(improve_ventilation, FailedFixes),
    \+ member(replace_fan, FailedFixes).

diagnose(router, internal, Symptoms, FailedFixes, thermal_sensor_failure) :-
    member(overheating, Symptoms),
    member(improve_ventilation, FailedFixes),
    member(replace_fan, FailedFixes),
    \+ member(replace_thermal_sensor, FailedFixes).

diagnose(router, internal, Symptoms, FailedFixes, full_board_failure) :-
    (member(overheating, Symptoms); member(low_performance, Symptoms)),
    member(improve_ventilation, FailedFixes),
    member(replace_fan, FailedFixes),
    member(replace_thermal_sensor, FailedFixes),
    member(update_firmware, FailedFixes),
    member(clear_cache, FailedFixes),
    member(replace_device, FailedFixes),
    member(reduce_cpu_load, FailedFixes),
    member(firmware_patch, FailedFixes),
    \+ member(replace_mainboard, FailedFixes).

% ===== PRINTER POWER RULES (Ordered: Simple → Advanced) =====

diagnose(printer, power, Symptoms, FailedFixes, printer_power_cable_issue) :-
    (member(led_off, Symptoms); member(no_power, Symptoms)),
    \+ member(check_power_cable, FailedFixes).

diagnose(printer, power, Symptoms, FailedFixes, printer_outlet_issue) :-
    (member(led_off, Symptoms); member(no_power, Symptoms)),
    member(check_power_cable, FailedFixes),
    \+ member(check_power_outlet, FailedFixes).

diagnose(printer, power, Symptoms, FailedFixes, printer_power_button_issue) :-
    (member(led_off, Symptoms); member(no_power, Symptoms)),
    member(check_power_cable, FailedFixes),
    member(check_power_outlet, FailedFixes),
    \+ member(check_power_button, FailedFixes).

diagnose(printer, power, Symptoms, FailedFixes, printer_power_supply_issue) :-
    (member(led_off, Symptoms); member(no_power, Symptoms)),
    member(check_power_cable, FailedFixes),
    member(check_power_outlet, FailedFixes),
    member(check_power_button, FailedFixes),
    \+ member(replace_printer_power_supply, FailedFixes).

diagnose(printer, power, Symptoms, FailedFixes, printer_fuse_blow) :-
    (member(led_off, Symptoms); member(no_power, Symptoms)),
    member(check_power_cable, FailedFixes),
    member(check_power_outlet, FailedFixes),
    member(check_power_button, FailedFixes),
    member(replace_printer_power_supply, FailedFixes),
    \+ member(replace_printer_fuse, FailedFixes).

diagnose(printer, power, Symptoms, FailedFixes, printer_internal_power_failure) :-
    (member(led_off, Symptoms); member(no_power, Symptoms)),
    member(check_power_cable, FailedFixes),
    member(check_power_outlet, FailedFixes),
    member(check_power_button, FailedFixes),
    member(replace_printer_power_supply, FailedFixes),
    member(replace_printer_fuse, FailedFixes),
    \+ member(replace_internal_psu, FailedFixes).

diagnose(printer, power, Symptoms, FailedFixes, printer_logic_board_failure) :-
    (member(led_off, Symptoms); member(no_power, Symptoms)),
    member(check_power_cable, FailedFixes),
    member(check_power_outlet, FailedFixes),
    member(check_power_button, FailedFixes),
    member(replace_printer_power_supply, FailedFixes),
    member(replace_printer_fuse, FailedFixes),
    member(replace_internal_psu, FailedFixes),
    \+ member(replace_logic_board, FailedFixes).

% ===== PRINTER CONNECTIVITY RULES (Ordered: Simple → Advanced) =====

diagnose(printer, connectivity, Symptoms, FailedFixes, printer_driver_issue) :-
    member(not_printing, Symptoms),
    \+ member(reinstall_driver, FailedFixes).

diagnose(printer, connectivity, Symptoms, FailedFixes, printer_usb_issue) :-
    member(not_printing, Symptoms),
    member(reinstall_driver, FailedFixes),
    \+ member(check_usb, FailedFixes).

diagnose(printer, connectivity, Symptoms, FailedFixes, printer_network_issue) :-
    member(not_printing, Symptoms),
    member(reinstall_driver, FailedFixes),
    member(check_usb, FailedFixes),
    \+ member(check_network, FailedFixes).

diagnose(printer, connectivity, Symptoms, FailedFixes, printer_spooler_issue) :-
    member(not_printing, Symptoms),
    member(reinstall_driver, FailedFixes),
    member(check_usb, FailedFixes),
    member(check_network, FailedFixes),
    \+ member(clear_spooler, FailedFixes).

diagnose(printer, connectivity, Symptoms, FailedFixes, printer_usb_port_failure) :-
    member(not_printing, Symptoms),
    member(reinstall_driver, FailedFixes),
    member(check_usb, FailedFixes),
    member(check_network, FailedFixes),
    member(clear_spooler, FailedFixes),
    \+ member(replace_usb_port, FailedFixes).

diagnose(printer, connectivity, Symptoms, FailedFixes, printer_firmware_sync_issue) :-
    member(not_printing, Symptoms),
    member(reinstall_driver, FailedFixes),
    member(check_usb, FailedFixes),
    member(check_network, FailedFixes),
    member(clear_spooler, FailedFixes),
    member(replace_usb_port, FailedFixes),
    \+ member(reflash_firmware, FailedFixes).

diagnose(printer, connectivity, Symptoms, FailedFixes, printer_protocol_mismatch) :-
    member(not_printing, Symptoms),
    member(reinstall_driver, FailedFixes),
    member(check_usb, FailedFixes),
    member(check_network, FailedFixes),
    member(clear_spooler, FailedFixes),
    member(replace_usb_port, FailedFixes),
    member(reflash_firmware, FailedFixes),
    \+ member(change_protocol, FailedFixes).

% ===== PRINTER INTERNAL RULES (Ordered: Simple → Advanced) =====

diagnose(printer, internal, Symptoms, FailedFixes, paper_jam_issue) :-
    member(paper_jam, Symptoms),
    \+ member(clear_paper_path, FailedFixes).

diagnose(printer, internal, Symptoms, FailedFixes, print_quality_issue) :-
    member(print_quality_poor, Symptoms),
    \+ member(replace_ink, FailedFixes).

diagnose(printer, internal, Symptoms, FailedFixes, printhead_issue) :-
    member(print_quality_poor, Symptoms),
    member(replace_ink, FailedFixes),
    \+ member(clean_printhead, FailedFixes).

diagnose(printer, internal, Symptoms, FailedFixes, printer_overheating_issue) :-
    member(overheating, Symptoms),
    \+ member(improve_printer_ventilation, FailedFixes).

diagnose(printer, internal, Symptoms, FailedFixes, printer_firmware_issue) :-
    member(low_performance, Symptoms),
    \+ member(update_printer_firmware, FailedFixes).

diagnose(printer, internal, Symptoms, FailedFixes, printer_hardware_failure) :-
    member(low_performance, Symptoms),
    member(update_printer_firmware, FailedFixes),
    \+ member(replace_printer_hardware, FailedFixes).

diagnose(printer, internal, Symptoms, FailedFixes, roller_wear_issue) :-
    member(paper_jam, Symptoms),
    member(clear_paper_path, FailedFixes),
    \+ member(replace_roller, FailedFixes).

diagnose(printer, internal, Symptoms, FailedFixes, toner_sensor_failure) :-
    member(print_quality_poor, Symptoms),
    member(replace_ink, FailedFixes),
    member(clean_printhead, FailedFixes),
    \+ member(replace_toner_sensor, FailedFixes).

diagnose(printer, internal, Symptoms, FailedFixes, alignment_motor_failure) :-
    (member(paper_jam, Symptoms); member(print_quality_poor, Symptoms)),
    member(clear_paper_path, FailedFixes),
    member(replace_roller, FailedFixes),
    member(replace_ink, FailedFixes),
    member(clean_printhead, FailedFixes),
    member(replace_toner_sensor, FailedFixes),
    \+ member(replace_alignment_motor, FailedFixes).

diagnose(printer, internal, Symptoms, FailedFixes, full_mechanical_failure) :-
    (member(paper_jam, Symptoms); member(print_quality_poor, Symptoms); member(low_performance, Symptoms)),
    member(clear_paper_path, FailedFixes),
    member(replace_roller, FailedFixes),
    member(replace_ink, FailedFixes),
    member(clean_printhead, FailedFixes),
    member(replace_toner_sensor, FailedFixes),
    member(replace_alignment_motor, FailedFixes),
    member(update_printer_firmware, FailedFixes),
    member(replace_printer_hardware, FailedFixes),
    \+ member(replace_full_mechanism, FailedFixes).

% Final fallback - always matches
diagnose(_, _, _, _, unknown_issue).