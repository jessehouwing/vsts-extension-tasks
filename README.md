[![Gitter](https://badges.gitter.im/jessehouwing/vsts-extension-tasks.svg)](https://gitter.im/jessehouwing/vsts-extension-tasks?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=body_badge)

# Release Notes
> **3-5-2016**

> - Fixed issue: Marketplace URI has changed
> - Fixed issue: Come tfx commands no longer return a JSON object but a JSON array

> **7-4-2016**

> - Fixed issue: Query Version no longer retrieves the latest, but the first version.
> - Fixed issue: Detection of globally installed tfx instance.
> - Fixed issue: Detection of locally installes tfx instance.

# Description

The VSTS Extension tasks help you to Package, Publish and Share your Extensions for Visual Studio Online and Team Foudnation Server 2015 update 2 using Build and Release Management.

Additional features include:

 * Overriding the Extension version in your extension manifest. (You can use the Build Number for example!);
 * Retrieve the latest published version from the marketplace;
 * Installing, Publishing, Sharing your extension from a Build or a Release Management workflow;
 * Overriding the Build Task version in your task manifest;
 * Overriding the visibility of the extension on the marketplace (Private, Public);
 * Building different versions for your own internal development, private testing and public consumption on the marketplace.

These tasks depend on the Cross Platform Commandline Tools and they can optionally pull down these tools automatically when they're not available.

Check out the project wiki for a [walkthrough explaining the setup of your build definition](https://github.com/jessehouwing/vsts-extension-tasks/wiki/How-to-Setup-build).


# Documentation

Please check the [Wiki](https://github.com/jessehouwing/vsts-extension-tasks/wiki).

If you have ideas or improvements to existing tasks, don't hestitate to leave feedback or [file an issue](https://github.com/jessehouwing/vsts-extension-tasks/issues).
