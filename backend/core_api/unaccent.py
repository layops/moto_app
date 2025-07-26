from django.db.models import Func

class Unaccent(Func):
    function = 'UNACCENT'
    template = '%(function)s(%(expressions)s)'