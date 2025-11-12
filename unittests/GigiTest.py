# run from GiGi DX12 Viewer in menu entry "File/Run Python Script"
# and observe the log for success/failure

# //////////////////////////////////////////////////////////////////////////
# //   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders    //
# //  Copyright (c) 2024-2025 Electronic Arts Inc.  All rights reserved.  //
# //////////////////////////////////////////////////////////////////////////

import Host
import GigiArray
import numpy
from PIL import Image
import os

def extractImage(fileName, resourceName):
	Host.SetWantReadback(resourceName)
	Host.RunTechnique(2)
	Host.WaitOnGPU()

	lastReadback, success = Host.Readback(resourceName)

	TestPassed = True
	
	os.makedirs((Host.GetScriptPath() + "_GoldImages").replace("\\", "/"), exist_ok=True)
	os.makedirs((Host.GetScriptPath() + "_Test").replace("\\", "/"), exist_ok=True)

	fullTest = Host.GetScriptPath() + f"_Test/{fileName}.png"
	fullGold = Host.GetScriptPath() + f"_GoldImages/{fileName}.png"

	if success:
		lastReadbackNp = numpy.array(lastReadback)
		lastReadbackNp = lastReadbackNp.reshape(600, 800, 4)
		Image.fromarray(lastReadbackNp, "RGBA").save(fullTest)

	if os.path.exists(fullGold):
		img = numpy.asarray(Image.open(fullGold))
		if not numpy.array_equal(img, lastReadbackNp):
			Host.Log("Error", f"'{fileName}' did not match")
			TestPassed = False
	else:
		Host.Log("Error", f"'{fileName}' didn't exist, creating")
		Image.fromarray(lastReadbackNp, "RGBA").save(fullGold)
		TestPassed = False

	if(TestPassed):
		Host.Print(f"'{fileName}' passed");

	return TestPassed

Host.Print("\n\nShader To Human (S2H)   UnitTest\n\n")

# don't save gguser files during this script execution
Host.DisableGGUserSave(True)

# Load the technique, relative path
if not Host.LoadGG("s2h_unittests.gg"):
	Host.Print("Error: Cannot lind .gg file")
	sys.exit()
#	return False

# Set camera
Host.SetCameraPos(-2.9, 9.459, -21.1)
Host.SetCameraAltitudeAzimuth(-0.463, 6.00)

#Host.SetVariable("SmallLightRadius","1")

extractImage("GatherTest", "GatherTest.Output: B (UAV - After)");
extractImage("ScatterTest", "ScatterTest.Output: C (UAV - After)");
extractImage("3DTest", "3DTest.Output: A (UAV - After)");
extractImage("2DTest", "2DTest.Output: F (UAV - After)");
extractImage("TableTest", "TableTest.Output: E (UAV - After)");

Host.Print("\n\n")

