import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))


class TestSmoke(unittest.TestCase):
    def test_pacote_importa(self):
        import conversor

        self.assertEqual(conversor.__doc__, "Conversor de unidades.")


if __name__ == "__main__":
    unittest.main()
