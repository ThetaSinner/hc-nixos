machine.wait_for_unit("default.target")
machine.wait_for_unit("lair-keystore-for-0_5.service")
machine.wait_for_unit("conductor-0_5.service")
