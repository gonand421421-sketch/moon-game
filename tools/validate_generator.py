"""Compile generator/embedded sources and run pure-Luau accounting tests.
Usage: python3 tools/validate_generator.py --luau /path/to/luau --compiler /path/to/luau-compile
No Roblox engine behavior is simulated by the accounting tests.
"""
import argparse
from pathlib import Path
import re
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('--luau', default='luau')
parser.add_argument('--compiler', default='luau-compile')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
source = (root / 'LunarCleanupGenerator.lua').read_text()
embedded = dict(re.findall(r'(config|environment|economy|server|client)\.Source\s*=\s*\[==\[\n(.*?)\n\]==\]', source, re.S))
assert set(embedded) == {'config', 'environment', 'economy', 'server', 'client'}
assert "GetDataStore('LunarCleanup_v1')" in embedded['server']
assert "{'Scrub','Action','Feedback'}" in source
assert 'CreateBackdrop' not in embedded['environment']
assert 'LunarCleanupSky' not in embedded['client']
assert 'SpaceBackdrop' not in source
assert "SkyTexture='rbxasset://textures/blackBkg_square.png'" in embedded['config']
assert 'while true' not in embedded['environment']
assert 'Environment.StartClient()' in embedded['client']
assert embedded['client'].index('Environment.StartClient()') < embedded['client'].index("workspace:WaitForChild('LunarCleanup')")
# Test actual production sanitization, not a copied reimplementation.
sanitize = embedded['server'].split('local function cleanInteger', 1)[1].split('local function tell', 1)[0]
sanitize = 'local function cleanInteger' + sanitize
with tempfile.TemporaryDirectory(prefix='lunar-validation-') as directory:
    directory = Path(directory)
    for name, contents in {'generator': source, **embedded}.items():
        target = directory / (name + '.luau')
        target.write_text(contents)
        subprocess.run([args.compiler, '--null', str(target)], check=True, capture_output=True, text=True)
        print('SYNTAX PASS:', name)
    stub = 'local Color3={fromRGB=function(...) return {...} end,new=function(...) return {...} end}\n'
    stub += 'local C=(function()\n' + embedded['config'] + '\nend)()\n'
    stub += 'local E=(function()\n' + embedded['economy'].replace('local C=require(script.Parent.Config)', '') + '\nend)()\n'
    stub += sanitize
    target = directory / 'balance_spec.luau'
    target.write_text(stub + '\n' + (root / 'tests/balance_spec.luau').read_text())
    subprocess.run([args.luau, str(target)], check=True)
    target = directory / 'structure_spec.luau'
    template = (root / 'tests/roblox_structure_stub.luau').read_text()
    assert template.count('-- GENERATOR_GOES_HERE') == 1
    target.write_text(template.replace('-- GENERATOR_GOES_HERE', source))
    subprocess.run([args.luau, str(target)], check=True)
print('PASS: compilation, accounting, save identity, and structural mocks. Not Studio playtesting.')
