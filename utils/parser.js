if (typeof exports == "undefined") {
	exports = this;
}
else {
	// in nodejs land, we can use simple server side functions
	const fs = require('fs');
	const path = require('path');

	var findFile = (dir, fileName) => {
		const files = fs.readdirSync(dir);
		for (const file of files) {
			const filePath = path.join(dir, file);
			const stat = fs.statSync(filePath);
			if (stat.isFile() && file === fileName) {
				return filePath;
			} else if (stat.isDirectory()) {
				const foundPath = findFile(filePath, fileName);
				if (foundPath) {
					return foundPath;
				}
			}
		}
		return null;
	}

	// "overrides" readCodeFile in frontend ConfigurateJS when run from NodeJS
	var readCodeFile = filePath => {
		const directoryPath = './'
		const filename = path.basename(filePath);
		const result = findFile(directoryPath, filename);
		const data = fs.readFileSync(result, 'utf8');
		return data;
	};
}

function ParseFile(inputText) {
    console.assert(inputText != null);  // not null or undefined
	// index into input[], used for ++p
	this.p = 0;
	// get current character or '' if end was reached
	this.c = function () { return this.p < this.input.length ? this.input[this.p] : ''; };
	// get next character or '' if end was reached
	this.c2 = function () { return this.p + 1 < this.input.length ? this.input[this.p + 1] : ''; };
	// end of file
	this.eof = function () { return this.c() ? false : true; };
	// text to parse
	this.input = inputText;
	// line number starting from 1, for error handling
	this.lineNo = 1;
	// is updated each time when lineNo is increased 
	this.lineStartP = 0;
	// 
	this.getBackup = function () { return { p: this.p, lineNo: this.lineNo, lineStartP: this.lineStartP }; };
	//
	this.setBackup = function (backup) { this.p = backup.p; this.lineNo = backup.lineNo; this.lineStartP = backup.lineStartP; };
};

// void isWhiteSpaceOrLF(string c)
function isWhiteSpaceOrLF(c) {
	// todo: refine
	return c != '' && c <= ' ';
}

// without digits
// bool isNameCharacter(string c)
function isNameCharacter(c) {
	return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_';
}

// bool isNameCharacter(string c)
function isOperatorCharacter(c) {
	return c == '+' || c == '-' || c == '*' || c == '/' || c == '!'
		|| c == '%' || c == '&' || c == '|' || c == '(' || c == ')'
		|| c == '[' || c == ']' || c == '=' || c == '{' || c == '}'
		|| c == '<' || c == '>' || c == '~' || c == '?' || c == ':'
		|| c == ',' || c == ';' || c == '^' || c == '.' || c == '\'';
}

// void parseWhiteSpaceOrLF(ParseFile parseFile)
function parseWhiteSpaceOrLF(parseFile) {
	while (isWhiteSpaceOrLF(parseFile.c())) {
		if (!parseLineFeed(parseFile)) {
			// todo: '\t'
			++parseFile.spaces;
			++parseFile.p;
		}
	}
}

// void parseWhiteSpaceNoLF(ParseFile parseFile)
function parseWhiteSpaceNoLF(parseFile) {
	for (; ; ++parseFile.p) {
		if (!parseFile.c()) {
			break;
		}

		let c = parseFile.c();

		if (!(c == ' ' || c == '\t')) {
			break;
		}

		// todo: '\t'
		++parseFile.spaces;
	}
}

// bool parseLineFeed(ParseFile parseFile)
function parseLineFeed(parseFile) {
	if (parseFile.c() === '\n') // CR
	{
		++parseFile.p;
		++parseFile.lineNo;

		if (parseFile.c() === '\r') // CR+LF
			++parseFile.p;

		parseFile.lineStartP = parseFile.p;
		return true;
	}
	if (parseFile.c() === '\r') // LF
	{
		++parseFile.p;
		++parseFile.lineNo;

		if (parseFile.c() === '\n') // LF+CR
			++parseFile.p;

		parseFile.lineStartP = parseFile.p;
		return true;
	}
	return false;
}

// case sensitive
// bool parseStartsWith(ParseFile parseFile, string str)
function parseStartsWith(parseFile, str) {
	let backup = parseFile.getBackup();

	for (let i = 0; i < str.length; i++) {
		if (parseFile.c() != str.charAt(i)) {
			parseFile.setBackup(backup);
			return false;
		}
		++parseFile.p;
	}

	return true;
}

// @return true if a return was found
// bool parseToEndOfLine(ParseFile parseFile)
function parseToEndOfLine(parseFile) {
	while (parseFile.c()) {
		if (parseLineFeed(parseFile))
			return true;

		++parseFile.p;
	}

	return false;
}


// string parseLine(ParseFile parseFile)
function parseLine(parseFile) {
	let ret = "";

	let start = parseFile.p;
	let end = parseFile.p;

	for (; ;) {
		if (!parseFile.c()) {
			end = parseFile.p;
			break;
		}

		let backup = parseFile.p;

		if (parseLineFeed(parseFile)) {
			end = backup;
			break;
		}

		parseFile.p++;
	}
	return parseFile.input.substring(start, end);
}

// string parseGetCurrentLine(ParseFile parseFile)
function parseGetCurrentLine(parseFile) {
	let backup = parseFile.getBackup();
	parseFile.p = parseFile.lineStartP;
	let ret = parseLine(parseFile);
	parseFile.setBackup(backup);

	return ret;
}

// without digits
function isNameCharacter(c) {
	return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_';
}

function isDigitCharacter(c) {
	return c >= '0' && c <= '9';
}


// string or undefined parseNumber(ParseFile parseFile)
function parseNumber(parseFile) {
	let backup = parseFile.getBackup();

	let ret = "";

	if (parseFile.c() == '-') {
		ret += '-';
		++parseFile.p;
	}

	if (!isDigitCharacter(parseFile.c()) && parseFile.c() != '.') {
		parseFile.setBackup(backup);
		return;
	}

	while (isDigitCharacter(parseFile.c())) {
		ret += parseFile.c();
		++parseFile.p;
	}
	if (parseFile.c() == '.') {
		ret += parseFile.c();
		++parseFile.p;
		if (!isDigitCharacter(parseFile.c())) {
			parseFile.setBackup(backup);
			return;
		}

		while (isDigitCharacter(parseFile.c())) {
			ret += parseFile.c();
			++parseFile.p;
		}
	}
	if (parseFile.c() == 'f') {
		++parseFile.p;
	}

	// We could convert to number but JS drops digits behind comma and GLSL does not like that. 
	//	return Number(ret);
	// For now we assume the input language has the right Number type (float or int)
	return ret;
}

// string or undefined parseName(ParseFile parseFile)
function parseName(parseFile) {
	if (!isNameCharacter(parseFile.c())) {
		return undefined;
	}

	let ret = "";

	while (isNameCharacter(parseFile.c()) || isDigitCharacter(parseFile.c())) {
		ret += parseFile.c();
		++parseFile.p;
	}

	return ret;
}
// string or undefined parseName(ParseFile parseFile)
function parsePreprocessorLine(parseFile) {
	if (!parseStartsWith(parseFile, "#line")) {
		return undefined;
	}
	let ret = "";
	return ret;
}

// todo: error handling
// string or undefined parseName(ParseFile parseFile)
function parsePreprocessorInclude(parseFile) {
	if (!parseStartsWith(parseFile, "#include")) {
		return undefined;
	}

	parseWhiteSpaceNoLF(parseFile);

	let ret = "";

	// todo: support not only "" but <> too
	if (parseFile.c() == '\"') {
		++parseFile.p;

		while (parseFile.c() != '\"' && parseFile.c() != '') {
			ret += parseFile.c();
			++parseFile.p;
		}
		if (parseFile.c() == '\"')
			++parseFile.p;
	}

	return ret;
}

// not perfect but should be good for near all cases. Fixing should be easy
// string or undefined parseOperator(ParseFile parseFile)
function parseOperator(parseFile) {
	// fix HTML embedded code issues
	if (parseStartsWith(parseFile, "&gt;"))
		return ">";
	if (parseStartsWith(parseFile, "&lt;"))
		return "<";
	if (parseStartsWith(parseFile, "&ge;"))
		return ">=";
	if (parseStartsWith(parseFile, "&le;"))
		return "<=";
	if (parseStartsWith(parseFile, "&amp;"))
		return "&";

	let backup = parseFile.getBackup();

	let ret = "";

	// >1 character operator
	if (parseStartsWith(parseFile, '&&')
	|| parseStartsWith(parseFile, '<=')
	|| parseStartsWith(parseFile, '>=')
	|| parseStartsWith(parseFile, '!=')
	|| parseStartsWith(parseFile, '==')
	|| parseStartsWith(parseFile, '<<')
	|| parseStartsWith(parseFile, '>>')
	|| parseStartsWith(parseFile, '+=')
	|| parseStartsWith(parseFile, '*=')
	|| parseStartsWith(parseFile, '/=')
	|| parseStartsWith(parseFile, '-=')
	|| parseStartsWith(parseFile, '--')
	|| parseStartsWith(parseFile, '++')
	|| parseStartsWith(parseFile, '^=')
	|| parseStartsWith(parseFile, '::')
	) {
		parseFile.setBackup(backup);
		let c = parseFile.c();
		ret += c;
		++parseFile.p;
		c = parseFile.c();
		ret += c;
		++parseFile.p;
		return ret;
	}

	let c = parseFile.c();

	// 1 character operator
	if (isOperatorCharacter(c)) {
		ret += c;
		++parseFile.p;

		return ret;
	}

	parseFile.setBackup(backup);
	return;
}

// number parseLeadingSpaces(ParseFile parseFile)
function parseLeadingSpaces(parseFile) {
	let ret = 0;

	while (parseFile.c()) {
		let c = parseFile.c();

		if (c === ' ') {
			++parseFile.p;
			++ret;
		}
		else if (c === '\t') {
			++parseFile.p;
			ret = (ret + 4) & (~3);
		}
		else break;
	}

	return ret;
}

// string or undefined parseName(ParseFile parseFile)
function parseComment(parseFile) {
	let backup = parseFile.getBackup();

	if (parseFile.c() == '/') {
		++parseFile.p;
		if (parseFile.c() == '/') {
			++parseFile.p;
			return parseLine(parseFile);
		}
	}

	parseFile.setBackup(backup);
	return;
}

function parsePreprocessor(parseFile){
	let backup = parseFile.getBackup();
	if (parseFile.c() == '#') {
		++parseFile.p;
		// TODO: parse # macro here
		return parseLine(parseFile);
	}

	parseFile.setBackup(backup);
	return;
}

function parseMultilineComment(parseFile){
	let backup = parseFile.getBackup();
	let ret = "";
	if (parseFile.c() == '/') {
		ret += parseFile.c();
		++parseFile.p;
		if (parseFile.c() == '*') {
			while (parseFile.c()) {
				ret += parseFile.c();
				++parseFile.p;
				if(parseFile.c() == '*' && parseFile.c2()=='/'){
					// Move two chars
					ret += parseFile.c();
					++parseFile.p;
					ret += parseFile.c();
					++parseFile.p;
					return ret;
				}
			}
		}
	}

	parseFile.setBackup(backup);
	return;
}


// =======================================================================

function assert(condition, message) {
	if (!condition) {
		throw message || "Assertion failed";
	}
}

function unitTests() {
	{
		assert(true);
		assert(!false);
		assert('1');
		assert('0');
		assert(!0);
		assert(!('' >= '0'));
		assert('' <= '9');
	}
	{
		assert(isWhiteSpaceOrLF(' '));
		assert(isWhiteSpaceOrLF('\t'));
	}
	{
		let parseFile = new ParseFile("");
		assert(parseFile.eof());
	}
	{
		let parseFile = new ParseFile(" \t");
		assert(!parseFile.eof());
		parseWhiteSpaceNoLF(parseFile);
		assert(parseFile.eof());
	}
	{
		let parseFile = new ParseFile(" \n");
		assert(parseFile.p === 0);
		parseLineFeed(parseFile);
		assert(parseFile.p === 0);
		parseWhiteSpaceNoLF(parseFile);
		assert(parseFile.p === 1);
		parseLineFeed(parseFile);
		assert(parseFile.p === 2);
	}
	{
		let parseFile = new ParseFile("var");
		assert(!parseStartsWith(parseFile, "txt"));
		assert(!parseStartsWith(parseFile, "Var"));
		assert(parseStartsWith(parseFile, "var"));
	}
	{
		let parseFile = new ParseFile("aa1\n22b\n - \n");
		assert(parseLine(parseFile) === "aa1");
		assert(parseLine(parseFile) === "22b");
		assert(parseLine(parseFile) === " - ");
		assert(parseLine(parseFile) === "");
	}
	{
		assert(parseNumber(new ParseFile("123")) === "123");
		assert(parseNumber(new ParseFile("-922")) === "-922");
		assert(parseNumber(new ParseFile("")) === undefined);
		assert(parseNumber(new ParseFile("12.31")) === "12.31");
		assert(parseNumber(new ParseFile("12.31f")) === "12.31");
		assert(parseNumber(new ParseFile(".12")) === ".12");
	}
	{
		assert(parseName(new ParseFile("testMe")) === "testMe");
		assert(parseName(new ParseFile("@")) === undefined);
		assert(parseName(new ParseFile("12")) === undefined);
		assert(parseName(new ParseFile("1testMe")) === undefined);
		assert(parseName(new ParseFile("testMe1")) === "testMe1");
	}
	{
		assert(parseComment(new ParseFile("// testMe")) === " testMe");
		assert(parseComment(new ParseFile("//")) === "");
		assert(parseComment(new ParseFile("")) === undefined);
		assert(parseComment(new ParseFile("//aa\nbb")) === "aa");
		assert(parseComment(new ParseFile("/* */")) === undefined);
		assert(parseComment(new ParseFile(" \t//aa")) === undefined);
		assert(parseComment(new ParseFile(" \t//aa\nbb")) === undefined);
		//		assert(parseComment(new ParseFile("/*ABc*/")) === "Abc");
		//		assert(parseComment(new ParseFile("pre/*ABc*/post")) === "Abc");
		//		assert(parseComment(new ParseFile("/ /**//")) === "");
	}
	{
		assert(parseOperator(new ParseFile(">")) === ">");
		assert(parseOperator(new ParseFile(">=")) === ">=");
		assert(parseOperator(new ParseFile("&gt;")) === ">");
		assert(parseOperator(new ParseFile("<")) === "<");
		assert(parseOperator(new ParseFile("w")) === undefined);
	}

	{
		assert(parseLeadingSpaces(new ParseFile("test")) === 0);
		assert(parseLeadingSpaces(new ParseFile("test\na")) === 0);
		assert(parseLeadingSpaces(new ParseFile("  test\na")) === 2);
		assert(parseLeadingSpaces(new ParseFile("\ttest\na")) === 4);
		assert(parseLeadingSpaces(new ParseFile("\t  test\na")) === 6);
		assert(parseLeadingSpaces(new ParseFile(" \tAA")) === 4);
	}

	console.log("unitTests done");
}

function parseStartingLine(parseFile, removeleadingSpaces) {
	assert(removeleadingSpaces !== undefined);

	let leadingSpaces = parseLeadingSpaces(parseFile);
	if (leadingSpaces >= removeleadingSpaces)
		leadingSpaces -= removeleadingSpaces;

	return " ".repeat(leadingSpaces);
}

function insertString(original, toInsert, index) {
	return original.slice(0, index) + toInsert + original.slice(index);
}

// read hlsl code and transform to backend specific code e.g. glsl (not needed for glsl as we do this in a batch file)
// @param string parse(ParseFile parseFile, Backend backend) 
// @param fileName string for debugging, may be null
function parseHLSLCode(parseFile, backend, fileName) {
	if(fileName == null)
		fileName = "input.hlsl";

	let ret = "";

	// compute number of leading spaces
	parseLineFeed(parseFile); // we might start with "\n"
	const removeleadingSpaces = parseLeadingSpaces(parseFile);

	while (parseFile.c()) {
		let c = parseFile.c();

		if (c === '@') {
			// useful for debugging, add before code with error
			let breakpoint = 0;
			++parseFile.p;
			continue;
		}

		// todo: handle whitespace better
		if (c === ' ') {
			++parseFile.p;
			ret += " ";
			continue;
		}

		if (c === '\t') {
			++parseFile.p;
			ret += "   ";
			continue;
		}

		if (parseLineFeed(parseFile)) {
			ret += "\n";
			ret += parseStartingLine(parseFile, removeleadingSpaces);
			continue;
		}

		let v = parseComment(parseFile);
		if (v !== undefined) {
			ret += "//" + v + "\n";
			ret += parseStartingLine(parseFile, removeleadingSpaces);
			continue;
		}

		v = parseMultilineComment(parseFile);
		if(v !== undefined){
			ret += v;
			continue;
		}

		v = parseName(parseFile);
		if (v !== undefined) {
			let cv = backend.translateName(v);
			if (cv !== undefined)
				v = cv;

			ret += v;
			continue;
		}
		v = parsePreprocessorLine(parseFile);
		if (v !== undefined) {
//			ret += "#line ";
			// todo: extract file and line for parser.js error messages
//			ret += parseLine(parseFile);
			// WegGL cannot handle #line so we ommit
			parseLine(parseFile);
			continue;
		}
		v = parsePreprocessorInclude(parseFile);
		if (v !== undefined) {
			var lines = readCodeFile(v);

			const expandIncludes = backend.expandIncludes;

			if (expandIncludes === true && lines != undefined) {
				// append in front
				lines = "\n// ############################ begin #include \"" + v + "\" ############################\n" + lines;
				// append in back
				lines += "\n// ############################ end #include \"" + v + "\" ############################\n";
				parseFile.input = insertString(parseFile.input, lines, parseFile.p);
			}
			else {
				if (lines != undefined)
					ret += "#include \"" + v + "\"\n";
				else
					ret += "#include \"" + v + "\" // Error: File not found\n";
			}
			continue;
		}

		// Generic preprocessor handler
	    v = parsePreprocessor(parseFile);
		if (v!==undefined){
			ret += "#" + v + "\n";
			ret += parseStartingLine(parseFile, removeleadingSpaces);
			continue;
		}

		v = parseNumber(parseFile);
		if (v !== undefined) {
			ret += v;
			continue;
		}
		v = parseOperator(parseFile);
		if (v !== undefined) {
			ret += v;
			continue;
		}

		let errLine = parseGetCurrentLine(parseFile);

		console.log("... " + ret.slice(-200));	// get last 200 characters to have context to track down the error

		console.log(fileName + "(" + parseFile.lineNo + ") Error: Unknown character: '" + parseFile.c() + "' (ASCII " + parseFile.c().charCodeAt(0) + ")");
		errLine = errLine.replaceAll('\t', ' '); // to make the ----^ align properly
		console.log(errLine);
		v = parseName(parseFile);
		console.log('-'.repeat(parseFile.p - parseFile.lineStartP) + "^");

		// todo: report error at parseFile.lineNo
		assert(false, "parseFile error");
	}

	return ret;
}

var g_unitTestsDidRun = false;

// string parse(string inputText, Backend backend) 
// @param fileName string for debugging, may be null
function parse(inputText, backend, fileName) {
	if (!g_unitTestsDidRun) {
		g_unitTestsDidRun = true;
//		try {
			unitTests();
//		}
//		catch (error) {
//			assert(false, "unitTests failed");
//		}
	}

	let parseFile = new ParseFile(inputText);

	return parseHLSLCode(parseFile, backend, fileName);
}

if (typeof exports == "undefined") {
	exports = this;
}

exports.parse = parse;