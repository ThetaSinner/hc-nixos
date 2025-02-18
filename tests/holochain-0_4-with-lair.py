machine.wait_for_unit("default.target")
machine.wait_for_unit("lair-keystore-for-0_4.service")
machine.wait_for_unit("conductor-0_4.service")
