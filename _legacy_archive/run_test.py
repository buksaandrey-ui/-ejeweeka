import sys
sys.path.insert(0, 'aidiet-backend')
from tests.test_e2e_normalizer import test_shopping_list_generation
try:
    test_shopping_list_generation()
except Exception as e:
    import traceback
    traceback.print_exc()
