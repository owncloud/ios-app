#!/usr/bin/env python3
import argparse, pathlib, re, shutil, subprocess, sys, os

PATTERN = re.compile(r'(APP_SHORT_VERSION\s*=\s*)([0-9]+(?:\.[0-9]+){0,2})(\s*;)')

def sh(args, check=True, capture=False, verbose=False):
    if verbose:
        print("→", " ".join(args))
    proc = subprocess.run(args, check=False, text=True,
                          stdout=(subprocess.PIPE if capture else None),
                          stderr=(subprocess.PIPE if capture else None))
    if check and proc.returncode != 0:
        if capture:
            print(proc.stdout or "", end="")
            print(proc.stderr or "", file=sys.stderr, end="")
        raise subprocess.CalledProcessError(proc.returncode, args)
    return proc

def current_branch():
    p = sh(['git','rev-parse','--abbrev-ref','HEAD'], capture=True)
    return p.stdout.strip()

def git_top_level(verbose=False):
    try:
        out = sh(['git','rev-parse','--show-toplevel'], capture=True, verbose=verbose).stdout.strip()
        return out
    except subprocess.CalledProcessError:
        print('Error: not a git repo.', file=sys.stderr); sys.exit(1)

def ensure_clean(allow_dirty=False, verbose=False):
    if allow_dirty: return
    w = subprocess.run(['git','diff','--quiet']).returncode != 0
    i = subprocess.run(['git','diff','--quiet','--cached']).returncode != 0
    if w or i:
        sh(['git','status','--porcelain'], check=False, verbose=verbose)
        print('Error: working tree is dirty. Commit/stash or pass --allow-dirty.', file=sys.stderr); sys.exit(1)

def switch_branch(branch, recreate=False, dry_run=False, verbose=False):
    exists = (subprocess.run(['git','rev-parse','--verify',branch],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0)
    # Use switch; fallback to checkout only if switch fails
    cmds = []
    if recreate:   cmds = [['git','switch','-C',branch], ['git','checkout','-B',branch]]
    elif exists:   cmds = [['git','switch',branch],      ['git','checkout',branch]]
    else:          cmds = [['git','switch','-c',branch], ['git','checkout','-b',branch]]

    if dry_run:
        print(f'[dry-run] Would switch/create: {branch} (exists={exists}, recreate={recreate})')
        return

    before = current_branch()
    for cmd in cmds:
        try:
            sh(cmd, verbose=verbose)
            break
        except subprocess.CalledProcessError:
            continue
    after = current_branch()
    print(f'Branch: {before} → {after}')
    if after != branch:
        raise RuntimeError(f'Failed to switch/create branch "{branch}"')

def bump(ver: str, part: str) -> str:
    nums = [int(x) for x in ver.split('.')]
    while len(nums) < 3: nums.append(0)
    M, m, p = nums[:3]
    return f'{M+1}.0.0' if part=='major' else (f'{M}.{m+1}.0' if part=='minor' else f'{M}.{m}.{p+1}')

def update_pbxproj(pbxproj: pathlib.Path, part: str, dry_run: bool, verbose: bool):
    text = pbxproj.read_text(encoding='utf-8')
    matches = list(PATTERN.finditer(text))
    if not matches:
        print(f'Error: no APP_SHORT_VERSION found in {pbxproj}', file=sys.stderr); sys.exit(2)
    old_ver = matches[0].group(2)
    new_ver = bump(old_ver, part)
    new_text = PATTERN.sub(lambda m: f'{m.group(1)}{new_ver}{m.group(3)}', text)
    count = len(matches)

    if dry_run:
        print(f'[dry-run] Would bump {pbxproj}: {old_ver} -> {new_ver} ({count})')
    else:
        backup = pbxproj.with_suffix(pbxproj.suffix + '.bak')
        shutil.copy2(pbxproj, backup)
        pbxproj.write_text(new_text, encoding='utf-8')
        print(f'Updated {pbxproj}: {old_ver} -> {new_ver} ({count}); backup: {backup}')
    return old_ver, new_ver, count

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--project', required=True, help='Path to .xcodeproj')
    ap.add_argument('--part', choices=['major','minor','patch'], default='minor')
    ap.add_argument('--branch-name', default='chore/bump-version')
    ap.add_argument('--recreate-branch', action='store_true')
    ap.add_argument('--allow-dirty', action='store_true')
    ap.add_argument('--dry-run', action='store_true')
    ap.add_argument('-v','--verbose', action='store_true')
    args = ap.parse_args()

    repo_root = git_top_level(verbose=args.verbose)
    os.chdir(repo_root)
    print(f'Repo root: {repo_root}')
    print('Current branch:', current_branch())

    ensure_clean(args.allow_dirty, verbose=args.verbose)

    xcodeproj = pathlib.Path(args.project)
    if not xcodeproj.is_absolute():
        xcodeproj = pathlib.Path(repo_root) / xcodeproj
    if xcodeproj.suffix != '.xcodeproj':
        print('Error: --project must be a .xcodeproj', file=sys.stderr); sys.exit(1)
    pbxproj = xcodeproj / 'project.pbxproj'
    if not pbxproj.exists():
        print(f'Error: {pbxproj} not found', file=sys.stderr); sys.exit(1)

    switch_branch(args.branch_name, recreate=args.recreate_branch,
                  dry_run=args.dry_run, verbose=args.verbose)
    old_ver, new_ver, _ = update_pbxproj(pbxproj, args.part, args.dry_run, args.verbose)

    if args.dry_run:
        print('[dry-run] Would: git add + git commit'); return

    sh(['git','add',str(pbxproj)], verbose=args.verbose)
    msg = f'chore: bump APP_SHORT_VERSION to {new_ver}'
    sh(['git','commit','-m',msg], verbose=args.verbose)
    print(f'Committed: {msg}')
    print(f'Push with:\n  git push -u origin {args.branch_name}')

if __name__ == '__main__':
    main()
