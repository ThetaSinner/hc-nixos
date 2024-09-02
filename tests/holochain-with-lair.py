machine.wait_for_unit("default.target")
machine.wait_for_unit("lair-keystore.service")
machine.wait_for_unit("conductor2.service")
