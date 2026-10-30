#!/usr/bin/env python3
import sys
import unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
from check_m1_matrix import validate_matrix, RUNTIME_MEASURED, RUNTIME_MEASURED_STATUS

class MeasuredScopeControls(unittest.TestCase):
    matrix=(Path(__file__).resolve().parents[1]/'.review/m1_ac_matrix.md').read_text()
    def changed(self,gate,status,evidence):
        lines=self.matrix.splitlines()
        for i,line in enumerate(lines):
            if line.startswith('| '+gate+' |'):
                cells=line.split('|');cells[3]=' '+status+' ';cells[4]=' '+evidence+' ';lines[i]='|'.join(cells);break
        else:self.fail('missing gate')
        return '\n'.join(lines)
    def test_exact_measured_triples_allowed(self):
        self.assertEqual(len(RUNTIME_MEASURED),9) # 8 runtime rows + supporting A8 alias, not9/18
        self.assertEqual(validate_matrix(self.matrix),[])
    def test_fabricated_run_rejected_even_with_measured_status(self):
        for gate,evidence in RUNTIME_MEASURED.items():
            self.assertTrue(validate_matrix(self.changed(gate,RUNTIME_MEASURED_STATUS,evidence.replace('40818428101','40631790078'))))
    def test_borrowed_real_other_row_artifact_rejected(self):
        evidence=RUNTIME_MEASURED['A9.3 injected RNG']
        self.assertTrue(validate_matrix(self.changed('A9.2 accumulator',RUNTIME_MEASURED_STATUS,evidence)))
    def test_real_replay_citation_cannot_upgrade_unrun_creature_gate(self):
        evidence=RUNTIME_MEASURED['A9.4 replay ×3']
        for gate in ('AC-201','AC-202','AC-204','FA-3','FA-4','FA-5','FA-6'):
            self.assertTrue(validate_matrix(self.changed(gate,RUNTIME_MEASURED_STATUS,evidence)))

if __name__=='__main__':unittest.main(verbosity=2)
