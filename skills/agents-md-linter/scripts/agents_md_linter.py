import re
import sys
import argparse

# AGENTS.md Linter
# Analyzes AGENTS.md content for anti-patterns and working patterns.
# Regex-based detection, no LLM. Scores 0-100.

# ANSI color codes based on .aml- CSS classes
class Colors:
    # Based on .aml-score-green/yellow/red and general text colors
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'  # Standard green for success
    WARNING = '\033[93m'  # Standard yellow for warnings
    FAIL = '\033[91m'     # Standard red for failures
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

class AgentsMdLinter:
    def __init__(self):
        # this.antiPatterns = [ ... ]
        self.antiPatterns = [
            {
                'name': 'Prose without commands',
                'desc': 'Paragraphs over 50 characters with no backtick-enclosed commands',
                'penalty': 15,
                'test': self._test_prose
            },
            {
                'name': 'Ambiguous directives',
                'desc': 'Vague words like "careful", "where possible", "gracefully" that agents can\'t act on',
                'penalty': 10,
                'maxPenalty': 20,
                'test': self._test_ambiguous
            },
            {
                'name': 'Contradictory priorities',
                'desc': '3+ directive bullets without explicit priority numbering',
                'penalty': 15,
                'test': self._test_contradictory
            },
            {
                'name': 'Style without enforcement',
                'desc': 'References a style guide without a CLI command to enforce it',
                'penalty': 10,
                'test': self._test_style_enforcement
            }
        ]

        # this.workingPatterns = [ ... ]
        self.workingPatterns = [
            {
                'name': 'Command-first instructions',
                'desc': 'Lines with backtick-enclosed commands',
                'bonus': 15,
                'threshold': 5,
                'test': self._test_command_first
            },
            {
                'name': 'Closure definitions',
                'desc': '"Definition of done", exit codes, or numbered completion criteria',
                'bonus': 10,
                'test': self._test_closure
            },
            {
                'name': 'Task-organized sections',
                'desc': 'Headings starting with "When" for task-based organization',
                'bonus': 10,
                'test': self._test_task_organized
            },
            {
                'name': 'Escalation rules',
                'desc': '"if...stop", "never:", "when blocked" patterns',
                'bonus': 10,
                'test': self._test_escalation
            }
        ]

    # test: function (text) { ... }
    def _test_prose(self, text):
        lines = text.split('\n')
        proseLines = []
        inCodeBlock = False
        for i, line_raw in enumerate(lines):
            line = line_raw.strip()
            # if (line.indexOf('```') === 0) { inCodeBlock = !inCodeBlock; continue; }
            if line.startswith('```'):
                inCodeBlock = not inCodeBlock
                continue
            if inCodeBlock:
                continue
            # // Skip headings, list items, empty lines
            # if (!line || line.charAt(0) === '#' || line.charAt(0) === '-' || line.charAt(0) === '*') continue;
            if not line or line[0] in ['#', '-', '*']:
                continue
            # if (line.length > 50 && line.indexOf('`') === -1) { ... }
            if len(line) > 50 and '`' not in line:
                proseLines.append({'line': i + 1, 'text': line[:60] + '...'})
        
        # return proseLines.length > 0 ? { ... } : { found: false };
        if proseLines:
            return {
                'found': True,
                'count': len(proseLines),
                'details': [f"Line {p['line']}: \"{p['text']}\"" for p in proseLines[:3]]
            }
        return {'found': False}

    def _test_ambiguous(self, text):
        # // Strip fenced code blocks before scanning
        # var textNoCode = text.replace(/```[\s\S]*?```/g, '');
        textNoCode = re.sub(r'```[\s\S]*?```', '', text)
        
        # var ambiguous = [ ... ]
        ambiguous = [
            {'word': 'careful', 'regex': r'\bcareful(ly)?\b'},
            {'word': 'where possible', 'regex': r'\bwhere possible\b'},
            {'word': 'gracefully', 'regex': r'\bgracefully\b'},
            {'word': 'appropriate', 'regex': r'\bappropriate(ly)?\b'},
            {'word': 'as needed', 'regex': r'\bas needed\b'},
            {'word': 'properly', 'regex': r'\bproperly\b'},
            {'word': 'reasonable', 'regex': r'\breasonabl[ey]\b'},
            {'word': 'try to', 'regex': r'\btry to\b'}
        ]
        
        found = []
        total_count = 0
        for a in ambiguous:
            # var matches = textNoCode.match(a.regex);
            matches = re.findall(a['regex'], textNoCode, re.IGNORECASE)
            if matches:
                found.append({'word': a['word'], 'count': len(matches)})
                total_count += len(matches)
        
        # return found.length > 0 ? { ... } : { found: false };
        if found:
            return {
                'found': True,
                'count': total_count,
                'details': [f"\"{f['word']}\" \u00d7 {f['count']}" for f in found]
            }
        return {'found': False}

    def _test_contradictory(self, text):
        lines = text.split('\n')
        bulletRuns = []
        currentRun = []
        inCodeBlock = False
        for i, line_raw in enumerate(lines):
            line = line_raw.strip()
            # if (line.indexOf('```') === 0) { inCodeBlock = !inCodeBlock; continue; }
            if line.startswith('```'):
                inCodeBlock = not inCodeBlock
                continue
            if inCodeBlock:
                continue
            # if (line.charAt(0) === '-' || line.charAt(0) === '*') { ... }
            if line and (line[0] == '-' or line[0] == '*'):
                currentRun.append({'line': i + 1, 'text': line})
            else:
                if len(currentRun) >= 3:
                    bulletRuns.append(currentRun)
                currentRun = []
        if len(currentRun) >= 3:
            bulletRuns.append(currentRun)

        # // Check if any long bullet run lacks "Priority" or numbered ordering
        unprioritized = []
        for run in bulletRuns:
            # var hasPriority = run.some(function (b) { return /priority\s*\d|#\d|\b\d+\.\s/i.test(b.text); });
            hasPriority = any(re.search(r'priority\s*\d|#\d|\b\d+\.\s', b['text'], re.IGNORECASE) for b in run)
            if not hasPriority:
                unprioritized.append(run)

        # return unprioritized.length > 0 ? { ... } : { found: false };
        if unprioritized:
            return {
                'found': True,
                'count': len(unprioritized),
                'details': [f"{len(run)} bullets starting at line {run[0]['line']} without priority ordering" for run in unprioritized[:2]]
            }
        return {'found': False}

    def _test_style_enforcement(self, text):
        # var styleRefs = text.match(/style guide|coding standard|naming convention/gi);
        styleRefs = re.findall(r'style guide|coding standard|naming convention', text, re.IGNORECASE)
        if not styleRefs:
            return {'found': False}

        # // Check if there's a linting command nearby
        # var hasLintCmd = /`(ruff|eslint|pylint|black|prettier|flake8|stylelint|rubocop)\b/.test(text);
        hasLintCmd = bool(re.search(r'`(ruff|eslint|pylint|black|prettier|flake8|stylelint|rubocop)\b', text))
        
        # return !hasLintCmd ? { ... } : { found: false };
        if not hasLintCmd:
            return {
                'found': True,
                'count': len(styleRefs),
                'details': ['References style guide but no linting command found (e.g., `ruff check`, `eslint`)']
            }
        return {'found': False}

    def _test_command_first(self, text):
        # var cmdMatches = text.match(/`[^`]{3,}`/g);
        cmdMatches = re.findall(r'`[^`]{3,}`', text)
        count = len(cmdMatches) if cmdMatches else 0
        
        # return count >= 5 ? { ... } : { ... };
        if count >= 5:
            return {
                'found': True,
                'count': count,
                'details': [f"{count} backtick commands found (threshold: 5)"]
            }
        return {
            'found': False,
            'count': count,
            'details': [f"{count} commands found (need 5+ for bonus)"]
        }

    def _test_closure(self, text):
        closurePatterns = [
            r'definition of done',
            r'task is complete when',
            r'exit(s| code)?\s*(0|zero)',
            r'\ball of the following\b',
            r'done when'
        ]
        # var found = closurePatterns.filter(function (p) { return p.test(text); });
        found = [p for p in closurePatterns if re.search(p, text, re.IGNORECASE)]
        
        # return found.length > 0 ? { ... } : { found: false };
        if found:
            return {
                'found': True,
                'count': len(found),
                'details': ['Explicit closure criteria detected']
            }
        return {'found': False}

    def _test_task_organized(self, text):
        # var whenHeadings = text.match(/^#{1,3}\s+When\b/gm);
        whenHeadings = re.findall(r'^#{1,3}\s+When\b', text, re.MULTILINE)
        count = len(whenHeadings) if whenHeadings else 0
        
        # return count > 0 ? { ... } : { found: false };
        if count > 0:
            return {
                'found': True,
                'count': count,
                'details': [f"{count} task-organized heading(s) (## When ...)"]
            }
        return {'found': False}

    def _test_escalation(self, text):
        escalationPatterns = [
            r'\bif\b.*\bstop\b',
            r'\bnever:',
            r'\bnever\b[^.]*\b(delete|force|skip|remove)\b',
            r'\bwhen blocked\b',
            r'\bdo not\b[^.]*\b(delete|force|skip)\b'
        ]
        # var found = escalationPatterns.filter(function (p) { return p.test(text); });
        found = [p for p in escalationPatterns if re.search(p, text, re.IGNORECASE)]
        
        # return found.length > 0 ? { ... } : { found: false };
        if found:
            return {
                'found': True,
                'count': len(found),
                'details': [f"{len(found)} escalation/safety rule(s) detected"]
            }
        return {'found': False}

    # lint(wrapper, text) { ... }
    def lint(self, text):
        # var score = 50; // baseline
        score = 50
        antiResults = []
        goodResults = []

        # // Run anti-pattern checks
        # this.antiPatterns.forEach(function (pattern) { ... });
        for pattern in self.antiPatterns:
            result = pattern['test'](text)
            if result['found']:
                penalty = pattern['penalty']
                if 'maxPenalty' in pattern:
                    penalty = min(result['count'] * pattern['penalty'], pattern['maxPenalty'])
                score -= penalty
                antiResults.append({'name': pattern['name'], 'desc': pattern['desc'], 'penalty': penalty, 'result': result})
            else:
                antiResults.append({'name': pattern['name'], 'desc': pattern['desc'], 'penalty': 0, 'result': result})

        # // Run working pattern checks
        # this.workingPatterns.forEach(function (pattern) { ... });
        for pattern in self.workingPatterns:
            result = pattern['test'](text)
            if result['found']:
                score += pattern['bonus']
                goodResults.append({'name': pattern['name'], 'desc': pattern['desc'], 'bonus': pattern['bonus'], 'result': result})
            else:
                goodResults.append({'name': pattern['name'], 'desc': pattern['desc'], 'bonus': 0, 'result': result})

        # // Clamp score
        # score = Math.max(0, Math.min(100, score));
        score = max(0, min(100, score))

        # // Build results UI
        # this.renderResults(results, score, antiResults, goodResults);
        self._print_results(score, antiResults, goodResults)

    def _print_results(self, score, antiResults, goodResults):
        print(f"\n{Colors.BOLD}{Colors.HEADER}=== AGENTS.md Linter Result ==={Colors.ENDC}\n")
        
        # // Score label
        # var scoreLabel = score >= 70 ? 'Good — follows working patterns' : ...
        if score >= 70:
            score_color = Colors.OKGREEN
            score_label = 'Good — follows working patterns'
        elif score >= 40:
            score_color = Colors.WARNING
            score_label = 'Needs work — some anti-patterns detected'
        else:
            score_color = Colors.FAIL
            score_label = 'Significant issues — mostly prose, few actionable commands'

        print(f"{Colors.BOLD}Score: {score_color}{score} / 100{Colors.ENDC}")
        print(f"Status: {score_label}\n")

        # // Anti-patterns section
        print(f"{Colors.BOLD}{Colors.UNDERLINE}Anti-Patterns{Colors.ENDC}")
        for r in antiResults:
            # var icon = r.result.found ? '\u2717' : '\u2713';
            if r['result']['found']:
                print(f"  {Colors.FAIL}✗ {r['name']} (-{r['penalty']}){Colors.ENDC}")
                print(f"    Description: {r['desc']}")
                if 'details' in r['result']:
                    for d in r['result']['details']:
                        print(f"    - {d}")
            else:
                print(f"  {Colors.OKGREEN}✓ {r['name']}{Colors.ENDC}")
        print()

        # // Working patterns section
        print(f"{Colors.BOLD}{Colors.UNDERLINE}Working Patterns{Colors.ENDC}")
        for r in goodResults:
            # var icon = r.result.found ? '\u2713' : '\u2014';
            if r['result']['found']:
                print(f"  {Colors.OKGREEN}✓ {r['name']} (+{r['bonus']}){Colors.ENDC}")
                print(f"    Description: {r['desc']}")
                if 'details' in r['result']:
                    for d in r['result']['details']:
                        print(f"    - {d}")
            else:
                print(f"  {Colors.ENDC}— {r['name']}{Colors.ENDC}")
                if 'details' in r['result']:
                    for d in r['result']['details']:
                        print(f"    - {d}")
        print()

def main():
    parser = argparse.ArgumentParser(description="AGENTS.md Linter")
    parser.add_argument("file", help="Path to markdown file")
    args = parser.parse_args()
    try:
        with open(args.file, 'r', encoding='utf-8') as f:
            content = f.read()
        linter = AgentsMdLinter()
        linter.lint(content)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
