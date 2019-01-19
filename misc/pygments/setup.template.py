from setuptools import setup, find_packages

setup(
    name='pygments_ex',
    version='0.1',
    packages=find_packages(),
    entry_points='''
[pygments.lexers]
{lexers}
[pygments.styles]
{styles}
''',
    platforms = 'any',
)
