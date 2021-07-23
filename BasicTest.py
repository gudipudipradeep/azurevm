# -*- coding: utf-8 -*-
import unittest
import fact
class FactTesting(unittest.TestCase):
    def test_fact(self):
        self.assertEqual(fact.fact(10), 3628800)
        
if __name__ == '__main__':
    unittest.main()

