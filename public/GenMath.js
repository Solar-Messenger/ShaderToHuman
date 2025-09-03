
// IIFE to wrap global variables / Module Pattern
(function () {

    // during ImmediateMode processing we add the backend code here
    var g_imTxt = new String();
    // what type of code the backend should generate
    // "GLM|CSharp|HLSL|GLSL|glm-js" see "gBackends = "
    var g_CodeType = new String();
    // during ImmediateMode processing we add JS code here for the interactive display
    // start anonymous function and execute it right away so we can call return to jump out the code (for timeSlider)
    var g_imJSCode = "(function(name) {\n";

    // this will replace g_imJSCode and g_CodeType
    // e.g. { Backend_GLM, Backend_HLSL, Backend_GLSL }
    var g_backends;

    var g_Backend = {};

})(); // IIFE to wrap global variables end

// @param name e.g. "GLSL" or "GLM" or "HLSL"
// @return text code or undefined
function getBackendCode(codeType = g_CodeType) {
    console.assert(codeType != null);
    let backend = g_Backend;
    if(codeType != g_CodeType){
        backend = s2h.getBackend(codeType);
    }

    let ret = backend.code;
    if(ret !== undefined){
        return ret;
    }

    console.assert(0);
}


// -------------------------------------------------------------

function onPageEnd() {
    // uncomment for debugging
    //console.error(g_imJSCode);

    if (typeof g_imJSCode === 'undefined')
        return;

    // start anonymous function and execute it right away so we can call return to jump out the code (for timeSlider)
    if (g_imJSCode.length)
        g_imJSCode += "})();\n";

    eval(g_imJSCode);

    // uncomment for debugging, to log all backends
    /*
    for(var i = 0; i < g_backends.length; ++i) {
        console.error(g_backends[i].constructor.name + " = \n'" + g_backends[i].code + "'\n");
    }
    */
}

// used globals: g_imTxt, g_CodeType
// @param code "GLM|CSharp|HLSL|GLSL|GLSL|glm-js" or undefined/null
// @return success
function genSetup(codeType) {

    g_backends = [];

    g_CodeType = codeType;
    g_imTxt = "";
    g_CanvasContext = undefined;
    g_CanvasGLContext = undefined;
    g_Backend = s2h.getBackend(codeType || "");
    g_Backend.clear();

    // start anonymous function and execute it right away so we can call return to jump out the code (for timeSlider)
    g_imJSCode = "(function(name) {\n";
    // for timeSlider
    g_imJSCode += "var _absTime = getTimeSliderState();\n";

    // those are the only backends we support at the moment
    if (g_CodeType === "HLSL" || g_CodeType === "GLM" || g_CodeType === "GLSL" || g_CodeType === "glm-js")
        return true;

    if (g_CodeType === null)
        return false;

    console.error("ERROR: genSetup g_CodeType=" + g_CodeType);

    return false;
}

function genComment(txt) {
    g_Backend.comment(txt);
    //g_imTxt += "// " + txt + "\n";

     for (var i = 0; i < g_backends.length; ++i)
         g_backends[i].comment(txt);
}

// used globals: g_CodeType
// @param type HLSL name e.g. "float2x2|float3x3|float4x4" or "quat"
// @return type in Code language
function genRetType(type, code) {
    if (code === undefined || code === null){
        code = g_CodeType;
    }

    backend = s2h.getBackend(code);
    let retType = backend.genRetType(type);
    if(retType === undefined){
        console.error("ERROR: genRetType code=" + code + " '" + type + "'");
    }

    return retType;
}

// @param time relative time in seconds
function genTime(time) {
    g_imJSCode += "_absTime -= " + time + "; if(_absTime < 0) return;\n";
}

// e.g. float3 name = float3(1, 2, 3);
// @param value optional e.g. "2, 3" "2, 3, 4" "2, 3, 4, 5.1"
function genVar(dstType, name, value) {
    // todo: refactor
    g_imJSCode += "var" + " " + name + " = " + genRetType(dstType, "glm-js") + "(" + value + ");\n";
    g_Backend.genVar(dstType, name, value);
}

// e.g. float name = srcName.x;
// @param component "x" "y" "z" "w"
function genGetFloat(dstName, srcName, component) {
    if (g_CodeType === "glm-js")
        g_imTxt += "var " + dstName + " = " + srcName + "." + component + ";\n";
    else
        g_imTxt += "float " + dstName + " = " + srcName + "." + component + ";\n";
}

// e.g. float3x3 mat = float3x3(column0, column1, column2);
// avoid this way to initialize as it's confusing
function genFloat3x3Columns(dstType, dstName, column0, column1, column2) {
    var type = genRetType(dstType, g_CodeType);

    if (g_CodeType === "glm-js")
        g_imTxt += "var";
    else
        g_imTxt += type;

    if (g_CodeType === "HLSL") {
        g_imTxt += " " + dstName + " = transpose(" + type + "(" + column0 + ", " + column1 + ", " + column2 + "));\n";
        // HLSL float3x3 mat = float3x3(row0, row1, row2);
        return;
    } else if (g_CodeType === "GLM" || g_CodeType === "glm-js") {
        g_imTxt += " " + dstName + " = " + type + "(" + column0 + ", " + column1 + ", " + column2 + ");\n";
        return;
    }

    console.error("ERROR: genFloat3x3Columns");
}

// e.g. float3x3 dstName = transpose(srcName)
// used globals: g_imTxt, g_CodeType
// @param dstType HLSL name e.g. "float2x2|float3x3|float4x4"
function genTranspose(dstType, dstName, srcName) {
    g_imTxt += genRetType(dstType);

    var pre = (g_CodeType === "GLM") ? "glm::" : "";

    g_imTxt += " " + dstName + " = " + pre + "transpose(" + srcName + ");\n";
}

// e.g. float3 dstName = normalize(srcName)
// used globals: g_imTxt, g_CodeType
// @param dstType HLSL name e.g. "float2x2|float3x3|float4x4"
function genNormalize(dstType, dstName, srcName) {
    g_imTxt += genRetType(dstType);

    var pre = (g_CodeType === "GLM") ? "glm::" : "";

    g_imTxt += " " + dstName + " = " + pre + "normalize(" + srcName + ");\n";
}

// used globals: g_imTxt, g_CodeType
// @param dstType HLSL name e.g. "float2x2|float3x3|float4x4"
function genMatrixMul(dstType, dstName, src1, src2) {
    var type = genRetType(dstType);

    if (g_CodeType === "glm-js")
        g_imTxt += "var";
    else
        g_imTxt += type;

    if (g_CodeType === "HLSL") {
        g_imTxt += " " + dstName + " = mul(" + src1 + ", " + src2 + ");\n";
        return;
    } else if (g_CodeType === "GLM" || g_CodeType === "GLSL" || g_CodeType === "glm-js") {
        g_imTxt += " " + dstName + " = " + src1 + " * " + src2 + ";\n";
        return;
    }

    console.error("ERROR: genMatrixMul");
}

// used globals: g_imTxt, g_CodeType
function genPrintVar(srcName) {
    if (g_CodeType === "GLM") {
        g_imTxt += 'print("' + srcName + '", ' + srcName + ");\n";
    }
    else {
        g_imTxt += '// print("' + srcName + '", ' + srcName + ");\n";
    }
}

// used globals: g_imTxt, g_CodeType
// @param dstType HLSL name e.g. "float"
// @param row like y 0/1/2/3
// @param column like x 0/1/2/3
function genMatrixGetRowColumn(dstType, dstName, srcName, row, column) {
    var type = genRetType(dstType);

    if (g_CodeType === "glm-js")
        g_imTxt += "var";
    else
        g_imTxt += type;

    if (g_CodeType === "GLM") {
        g_imTxt += " " + dstName + " = " + srcName + "[" + column + "][" + row + "];\n";
        return;
    }

    g_imTxt += " " + dstName + " = " + srcName + "[" + row + "][" + column + "];\n";
    // The zero - based row - column position:
    // _m00, _m01, _m02, _m03
    // The one - based row - column position:
    // _11, _12, _13, _14
}

// used globals: g_imTxt, g_CodeType
// @param row like y 0/1/2/3
// @param column like x 0/1/2/3
function genMatrixSetRowColumn(varName, row, column, value) {
    if (g_CodeType === "GLM") {
        g_imTxt += varName + "[" + column + "][" + row + "] = " + value + ";\n";
        return;
    }

    g_imTxt += varName + "[" + row + "][" + column + "] = " + value + ";\n";
    // The zero - based row - column position:
    // _m00, _m01, _m02, _m03
    // The one - based row - column position:
    // _11, _12, _13, _14
}

/*
// @param value e.g. "1.2, 1.3, 1.4", euler angles in radiants
function genEulerToQuat(varName, value)
{
    if (g_CodeType === "GLM") {
        g_imTxt += "glm::quat " + varName + " = glm::quat(glm::vec3(" + value + "));\n";
        return;
    }
    else if (g_CodeType === "HLSL") {
        g_imTxt += "float4 " + varName + " = EulerToQuat(float3(" + value + "));\n";
        return;
    }

    console.error("ERROR: genEulerToQuat");
}
*/

/*
function genQuatToFloat3x3(dstName, srcName) {
    var type = genRetType("float3x3");

    if (g_CodeType === "glm-js")
        g_imTxt += "var";
    else
        g_imTxt += type;

    if (g_CodeType === "GLM") {
        g_imTxt += " " + dstName + " = (" + type + ")" + srcName + ";\n";
        return;
    }
    else if(g_CodeType === "HLSL") {
        g_imTxt += " " + dstName + " = float3x3_cast(" + srcName + ");\n";
        return;
    }

    console.error("ERROR: genQuatToFloat3x3");
}
*/

// compare float with some threshold
// @param varName e.g. "test1"
// @param value e.g. "1.0f" or "12"
function genAssert(varName, value) {
    if (g_CodeType === "GLM") {
        // threshold comparison
        g_imTxt += "assert( fabsf(" + varName + " - " + value + ") < 0.0001f);\n";
        return;
    }
    else if (g_CodeType === "HLSL") {
        // threshold comparison
        g_imTxt += "assert(abs(" + varName + " - " + value + ") < 0.0001f);\n";
        return;
    }
}

// @param txt source code
// @param fileName string for debugging, may be null
function genWebGlCode(txt, fileName){
    console.assert(txt != null);
    const backend = s2h.getBackend('webgl');
    backend.genCode(txt, fileName);
}

// stores output in g_Backend for different backends
// @param fileName string for debugging, may be null (e.g. when called from Sandbox)
function genBackends(hlslCode, fileName) {

    console.assert(hlslCode, "cannot find the input file");
    hlslCode = hlslCode.replaceAll("//!KEEP ", "");
    hlslCode = hlslCode.replace(/^[ \t]*\r?\n/gm, '');  // remove more than single empty lines

    console.assert(hlslCode != null);
    g_Backend.genCode(hlslCode, fileName);
    genWebGlCode(hlslCode, fileName);
}

// @param filename e.g. "public/docs/intro_0.hlsl"
function getPrettyCodeFile(hlslFileName) {

    console.assert(hlslFileName.endsWith(".hlsl"), "fileName needs to have .hlsl extension");

    let hlslCode = readCodeFile(hlslFileName);
    
    console.assert(hlslCode, "cannot find the input file");

    let glslFileName = hlslFileName.replace(/\.hlsl$/, ".glsl");

    let glslCode = readCodeFile(glslFileName);

//    genBackends(hlslCode, hlslFileName);
    genBackends(glslCode, hlslFileName);
}

// Sandbox
function OnTextEditorCompile() {
    var code = document.getElementById("TextEditor").value;
    //    console.log(code);

    if (!genSetup(get("Code"))) {
        logError("Please specify a valid 'Code' backend.");
        return;
    }

    genBackends(code);

    const backendCode = getBackendCode(g_CodeType);
    if (backendCode !== undefined) {
        var el = document.getElementById("LogCode");
        el.innerHTML = hljs.highlight(backendCode, { language: 'cpp' }).value;
    }

    setup2DCanvas("2D", "myCanvas");
    setupGLCanvas("2D", "myWebGLCanvas");
}

function OnTextEditorChanged(value) {
    g_TextEditorContent = "";
    g_TextEditorContent = value;

    genBackends(value);
    genWebGlCode(value, "sandboxInput.hlsl");
}

// HLSL
var g_TextEditorContent =
    `// Like default Shadertoy code but in HLSL.
void mainImage( out float4 fragColor, in float2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    float2 uv = fragCoord / iResolution.xy;

    // Time varying pixel color
    float3 col = 0.5 + 0.5 * cos(iTime + uv.xyx + float3(0,2,4));

    // Output to screen
    fragColor = float4(col,1.0);
}`;


function genTextEditor() {
    imTxt += '<textarea id="TextEditor" rows="25" cols="80" spellcheck="false" oninput="OnTextEditorChanged(this.value);">' + g_TextEditorContent + '</textarea>';
    // Compile button
    imTxt += '<br><button onclick="OnTextEditorCompile()" title="Compile (<ALT> + <ENTER>)" style="border-width:1px; border-radius: 5px; border-color: #00000044;">&#9654;</button>';
    imTxt += ' compiled in .. secs';
    imTxt += '<br><button onclick="OnZipDownload()" title="Download All" style="border-width:1px; border-radius: 5px; border-color: #00000044;">&#9660;</button>';
    imTxt += ' Download Shader Zip<br><br>';
}

function OnZipDownload(){
    let codeType = 'hlsl';
    if(g_CodeType != 'hlsl')
        codeType = g_CodeType;
    window.location.href = `/zip?type=${codeType}`;
}

function OnFileClick(file)
{
    file = file.replaceAll('/','\\');
    g_TextEditorContent = readCodeFile(file);
    const textarea = document.getElementById('TextEditor');
    textarea.value = g_TextEditorContent;
}

function genFileList() {
    const genListItem = (file) => {
        file = file.replaceAll('\\','/');
        imTxt += `<li href="#" onclick="OnFileClick('${file}')" title="${file}">${file}</li>`
    };

    imTxt += "<div class='file-list'>";
    imTxt += "<ul>"
    for (let [key, val] of g_HLSLInputCode) {
        genListItem(key);
    }
    imTxt += "</ul>";
    imTxt += "</div>";
}


// @param type "2D" or "3D"
// @param style 0:dark, 1:bright (default)
// @param width in pixels, can be omitted, then a small default is taken e.g. 640
// @param height in pixels, can be omitted, then a small default is taken, e.g. 480
function genCanvas(type, style, width, height) {
    // default parameters, small enough to see more text as well
    if (style === undefined) style = 1;
    if (width === undefined) width = 480;
    if (height == undefined) height = width / 4 * 3;

    const styleName = (style == 0) ? "dark" : "bright";

    var name = 'myCanvas';
    var glName = 'myWebGLCanvas';

    // "hidden" glm-js 2D canvas is not needed, for now
    // As the camera is stored there and needed for 3D we just hide it.

    // tabindex='1' is a old trick to make it focusable (receive keydown)
    imTxt += `<canvas hidden tabindex='1' class="${styleName}" id="${name}" width="${width}" height="${height}"></canvas>`;

    // "timeSlider", accessed by name
    // Make slider under canvas to set time, to visualize progress over time.
    // Later we can add a play and pause button as well.
//    imTxt += `<div class="slidecontainer"><input type="range" min="0" max="10000" value="10000" class="slider" id="timeSlider" oninput="updateTimeSlider(this.value)" style="max-width: 508px; width: 100%;"></div>`;

    g_imJSCode += 'setup2DCanvas("' + type + '", "' + name + '");';

    // WebGL preview

    imTxt += `<canvas tabindex='1' id="${glName}" class="${styleName}" width="${width}" height="${height}"></canvas>`;
    g_imJSCode += 'setupGLCanvas("' + type + '", "' + glName + '");';
}

function genDrawPointCS(posVarName, colorVarName, radiusInCSY) {
    const line = 'drawPointCS(' + posVarName + ', ' + colorVarName + ', ' + radiusInCSY + ');\n';

    g_imTxt += line;
    g_imJSCode += line;
}

function genDrawPointWS(posVarName, colorVarName) {
    const line = 'drawPointWS(' + posVarName + ', ' + colorVarName + ');\n';

    g_imTxt += line;
    g_imJSCode += line;

    g_Backend.genDrawPointWS(posVarName, colorVarName);
}

function genDrawPointSS(posVarName, colorVarName) {
    const line = 'drawPointSS(' + posVarName + ', ' + colorVarName + ');\n';

    g_imTxt += line;
    g_imJSCode += line;
}

function genDrawBoxSS(leftTopVarName, bottomRightVarName, colorVarName) {
    const line = 'drawBoxSS(' + leftTopVarName + ', ' + bottomRightVarName + ', ' + colorVarName + ');\n';

    g_imTxt += line;
    g_imJSCode += line;
}

// @return time slider state
function getTimeSliderState() {
    var el = document.getElementById("timeSlider");

    if (el)
        return el.value / 1000.0;    // 0..10000 => 0..10
    else
        return 0.0;
}

function updateTimeSlider(value) {
    // redraw scene
    eval(g_imJSCode);
}
