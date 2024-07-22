# Compiling Friday Night Funkin'

0. Setup
    - Download Haxe from [Haxe.org](https://haxe.org)
    - Download Git from [git-scm.com](https://www.git-scm.com)
    - Do NOT download the repository using the Download ZIP button on GitHub or you may run into errors!
    - Instead, open a command prompt and do the following steps...
1. Run `cd the\directory\you\want\the\source\code\in` to specify which folder the command prompt is working in.
    - For example, `cd C:\Users\YOURNAME\Documents` would instruct the command prompt to perform the next steps in your Documents folder.
2. Run `git clone https://github.com/FunkinCrew/funkin.git` to clone the base repository.
3. Run `cd funkin` to enter the cloned repository's directory.
4. Run `git submodule update --init --recursive` to download the game's assets.
    - NOTE: By performing this operation, you are downloading Content which is proprietary and protected by national and international copyright and trademark laws. See [the LICENSE.md file for the Funkin.assets](https://github.com/FunkinCrew/funkin.assets/blob/main/LICENSE.md) repo for more information.
5. Run `haxelib --global install hmm` and then `haxelib --global run hmm setup` to install hmm.json
6. Run `hmm install` to install all haxelibs of the current branch
7. Run `haxelib run lime setup` to set up lime
8. Platform setup
   - For Windows, download the [Visual Studio Build Tools](https://aka.ms/vs/17/release/vs_BuildTools.exe)
        - When prompted, select "Individual Components" and make sure to download the following:
        - MSVC v143 VS 2022 C++ x64/x86 build tools
        - Windows 10/11 SDK
    - Mac: [`lime setup mac` Documentation](https://lime.openfl.org/docs/advanced-setup/macos/)
    - Linux: [`lime setup linux` Documentation](https://lime.openfl.org/docs/advanced-setup/linux/)
    - HTML5: Compiles without any extra setup
    - Android:
      - Run `setup-android-[yourOS].bat` in the docs folder by clicking it to install the required development kits on your machine.
      - If for some reason the downloads don’t work (most likely JDK) [Download it directly.](https://adoptium.net/temurin/releases/?version=17)
      - (ONLY DO THIS STEP IF THE DOWNLOAD FAILED) After installing the JDK, make sure you know where it installed! If you installed using a `.msi` file, it should be somewhere around `C:\Program Files\`. Go and look for an`Eclipse Adoptium` folder and open it.
      - (ONLY DO THIS STEP IF THE DOWNLOAD FAILED look for a folder named something like `jdk-17`. Right click and click on `Copy as path`.
      - (ONLY DO THIS STEP IF THE DOWNLOAD FAILED) Go to your command prompt and type `haxelib run lime config JAVA_HOME [JdkPathYouCopied]`
      - after that is done delete the `temp` folder that just got made.
    - iOS:
      - Get Xcode from the app store on your MacOS Machine.
      - Download the iPhone SDK (First thing that pops up in Xcode)
      - Open up a terminal tab and do `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
9. If you are targeting for native, you may need to run `lime rebuild PLATFORM` and `lime rebuild PLATFORM -debug`
10. `lime test PLATFORM` ! Add `-debug` to enable several debug features such as time travel (`PgUp`/`PgDn` in Play State).

# Troubleshooting - GO THROUGH THESE STEPS BEFORE OPENING ISSUES ON GITHUB!

- During the cloning process, you may experience an error along the lines of `error: RPC failed; curl 92 HTTP/2 stream 0 was not closed cleanly: PROTOCOL_ERROR (err 1)` due to poor connectivity. A common fix is to run ` git config --global http.postBuffer 4096M`.
- Make sure your game directory has an `assets` folder! If it's missing, copy the path to your `funkin` folder and run `cd the\path\you\copied`. Then follow the guide starting from **Step 4**. 
- Check that your `assets` folder is not empty! If it is, go back to **Step 4** and follow the guide from there.
- The compilation process often fails due to having the wrong versions of the required libraries. Many errors can be resolved by deleting the `.haxelib` folder and following the guide starting from **Step 5**.
