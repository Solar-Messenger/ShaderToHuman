const fs = require('fs');
const path = require('path');
const AdmZip = require("adm-zip");
const fsPromises = require('fs/promises');
var compiler = require("c-preprocessor");
const backends = require('./backends.js')

// TODO: Credit?
function findFiles(dirPath, extensions, fileList = []) {
    const files = fs.readdirSync(dirPath);

    for (const file of files) {
        const filePath = path.join(dirPath, file);
        const stat = fs.statSync(filePath);

        if (stat.isDirectory()) {
            findFiles(filePath, extensions, fileList); // Recursive call for subdirectories
        } else if (extensions.includes(path.extname(file))) {
            fileList.push(filePath);
        }
    }

    return fileList;
}

function search(directoryToSearch = './') {
    const targetExtensions = ['.hlsl', '.glsl'];
    return findFiles(directoryToSearch, targetExtensions);
}

function searchFile(file, directoryToSearch = './') {
    const files = search(directoryToSearch);
    for (let i = 0; i < files.length; i++) {
        const fpath = path.normalize(files[i]);
        file = path.normalize(file);
        if (fpath.toLowerCase().includes(file.toLowerCase())) {
            return files[i];
        }
    }
}

function zipFiles(fileList, shaderType = 'hlsl') {
    var zip = new AdmZip();
    const loads = fileList.map(path => fsPromises.readFile(path));
    return Promise.all(loads)
        .then(buffers => {
            buffers.forEach((buffer, index) => {
                const path = fileList[index];
                let code = buffer.toString();
                let filePath = path;
                if (shaderType.toLowerCase() !== 'hlsl') {
                    try{
                        var backend = backends.s2h.getBackend(shaderType);
                        backend.genCode(code);
                        code = backend.code;
                    }
                    catch(err){
                        console.log('Skipping file, failed to parse: %s', filePath);
                        console.log(err);
                        return;
                    }
                }

                code = code.replaceAll(".hlsl", "." + shaderType.toLowerCase());
                filePath = filePath.replace(".hlsl", "." + shaderType.toLowerCase());
                zip.addFile(filePath, Buffer.from(code));
            });
            return zip.toBufferPromise();
        })
        .catch(err => {
            console.log(err);
            return err;
        });
}

function preprocess(file) {
    const promise = new Promise(resolve => resolve(searchFile(file)));
    return promise
        .then(filePath => {
            return fsPromises.readFile(filePath);
        }).then(code => {
            return new Promise((resolve, reject) => {
                const options = {
                    basePath: './'
                };
                var preprocessor = new compiler.Compiler(options);

                preprocessor.on("success", result => resolve(result));
                preprocessor.on("error", err => reject(err));
                preprocessor.compile(code.toString('utf-8'));
            });
        }).catch(err => err);
}

module.exports.search = search;
module.exports.searchFile = searchFile;
module.exports.zipFiles = zipFiles;
module.exports.preprocess = preprocess;