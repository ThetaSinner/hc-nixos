machine.wait_for_unit("default.target")
# machine.succeed("systemctl status conductor | grep 'Status: \"Running\"'")
machine.wait_for_unit("lair-keystore", "lair", 90)
# machine.wait_for_unit("conductor", "conductor", 90)
