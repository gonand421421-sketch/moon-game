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
embedded = dict(re.findall(r'(config|environment|economy|regions|sectorView|celestial|surfaceRender|surfaceWorld|server|client)\.Source\s*=\s*\[==\[\n(.*?)\n\]==\]', source, re.S))
assert set(embedded) == {'config', 'environment', 'economy', 'regions', 'sectorView', 'celestial', 'surfaceRender', 'surfaceWorld', 'server', 'client'}
assert "GetDataStore('LunarCleanup_v1')" in embedded['server']
assert "{'Scrub','Action','Feedback','Surface'}" in source
assert 'CreateBackdrop' not in embedded['environment']
assert 'LunarCleanupSky' not in embedded['client']
assert 'SpaceBackdrop' not in source
assert "SkyTexture='rbxasset://textures/blackBkg_square.png'" in embedded['config']
assert 'while true' not in embedded['environment']
assert 'Environment.StartClient()' in embedded['client']
assert embedded['client'].index('Environment.StartClient()') < embedded['client'].index("workspace:WaitForChild('LunarCleanup')")
# Freeze the working sky, economy and account behavior against the pre-expansion backup.
previous = (root / 'backups/LunarCleanupGenerator.pre-regional-surface.lua').read_text()
for name in ('config', 'environment', 'economy'):
    old = re.search(name + r'\.Source\s*=\s*\[==\[\n(.*?)\n\]==\]', previous, re.S)[1]
    assert embedded[name] == old, name + ' changed (sky/economy must stay frozen)'
old_server = re.search(r'server\.Source\s*=\s*\[==\[\n(.*?)\n\]==\]', previous, re.S)[1]
account_block = lambda text: text.split('local function cleanInteger', 1)[1].split('local function finite', 1)[0]
assert account_block(embedded['server']) == account_block(old_server), 'existing account/purchase behavior changed'
# Hexes are derived views: existing regional cell ownership/encoding must be identical.
pre_hex = (root / 'backups/LunarCleanupGenerator.pre-hex-workshop.lua').read_text()
old_regions = re.search(r'regions\.Source\s*=\s*\[==\[\n(.*?)\n\]==\]', pre_hex, re.S)[1]
for name in ('Access', 'At', 'Cell', 'Chunk', 'Unpack', 'BuildIndex', 'Encode', 'Decode', 'ChunkCellsAt'):
    pattern = r'function R\.' + name + r'\(.*?(?=\nfunction R\.|\n-- Hex sectors|\nreturn R)'
    assert re.search(pattern, embedded['regions'], re.S)[0].strip() == re.search(pattern, old_regions, re.S)[0].strip(), name + ' changed saved cell identity'
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
    stub += '\nlocal R=(function()\n' + embedded['regions'].replace('local C=require(script.Parent.Config)', '') + '\nend)()\n'
    target = directory / 'balance_spec.luau'
    target.write_text(stub + '\n' + (root / 'tests/balance_spec.luau').read_text() + '\n' + (root / 'tests/regions_spec.luau').read_text() + '\n' + (root / 'tests/hex_spec.luau').read_text())
    subprocess.run([args.luau, str(target)], check=True)
    target = directory / 'structure_spec.luau'
    template = (root / 'tests/roblox_structure_stub.luau').read_text()
    assert template.count('-- GENERATOR_GOES_HERE') == 1
    scrub = 'local function finite' + embedded['server'].split('local function finite', 1)[1].split('task.spawn(function()\n while not closing do', 1)[0]
    scrub_template = (root / 'tests/surface_scrub_spec.luau').read_text()
    assert scrub_template.count('-- SCRUB_HANDLER_GOES_HERE') == 1
    target.write_text(template.replace('-- GENERATOR_GOES_HERE', source) + '\n' + (root / 'tests/surface_world_spec.luau').read_text() + '\n' + scrub_template.replace('-- SCRUB_HANDLER_GOES_HERE', scrub) + '\n' + (root / 'tests/hex_scene_spec.luau').read_text())
    subprocess.run([args.luau, str(target)], check=True)
print('PASS: syntax, frozen sky/economy/accounts, regional indexing, mock persistence, and bounded visual loop. Not Studio playtesting.')
