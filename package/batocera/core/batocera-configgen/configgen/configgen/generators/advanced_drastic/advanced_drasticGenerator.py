from __future__ import annotations

import filecmp
import os
import shutil
from os import environ
import subprocess
from typing import TYPE_CHECKING

from ... import Command
from ...batoceraPaths import CONFIGS
from ...controller import generate_sdl_game_controller_config
from ..Generator import Generator

if TYPE_CHECKING:
    from pathlib import Path

    from ...types import HotkeysContext

class Advanced_DrasticGenerator(Generator):

    def getHotkeysContext(self) -> HotkeysContext:
        return {
            "name": "drastic",
            "keys": { "exit": "KEY_ESC" }
        }

    def generate(self, system, rom, playersControllers, metadata, guns, wheels, gameResolution):

        advanced_drastic_root = "/userdata/system/configs/advanced_drastic"
        advanced_drastic_bin = "/userdata/system/configs/advanced_drastic/launch.sh"
        advanced_drastic_conf = "/userdata/system/configs/advanced_drastic/config/drastic.cfg"

        board = os.popen("cat /boot/boot/batocera.board").read()
        board=board.rstrip("\n\r ")

        if os.path.isfile(advanced_drastic_root + "/batocera.board"):
            board_installed = os.popen("cat " + advanced_drastic_root + "/batocera.board").read()
            board_installed = board_installed.rstrip("\n\r ")
        else:
            board_installed = ""

        if (not os.path.exists(advanced_drastic_root)) or (board != board_installed):
            os.makedirs(advanced_drastic_root, exist_ok = True)
            os.system("cp -rv /usr/share/advanced_drastic/* /userdata/system/configs/advanced_drastic")
            if os.path.exists("/usr/share/advanced_drastic/devices/" + board ):
                os.system("cp -rv /usr/share/advanced_drastic/devices/" + board + "/* /userdata/system/configs/advanced_drastic")
            os.system("cp /boot/boot/batocera.board /userdata/system/configs/advanced_drastic")

        os.chdir(advanced_drastic_root)
        commandArray = [advanced_drastic_bin, rom]
        return Command.Command(
            array=commandArray,
            env={
                'DISPLAY': '0.0',
                'LIB_FB': '3',
                'SDL_GAMECONTROLLERCONFIG': generate_sdl_game_controller_config(playersControllers)
            })

