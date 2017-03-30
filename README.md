# ![Mobile Jazz Badge](https://raw.githubusercontent.com/mobilejazz/metadata/master/images/icons/mj-40x40.png) Google Drive Recovery Script

> A Script that helps you minimize damage when recovering deleted Google Drive files.

**drive-clean** is a **dart** terminal tool that can help you recover lost files when trying to restore a Google Drive backup.

I wrote this because I accidentally removed items within a shared folder at work.
Those items where not mine to recover, and hence... big mess!

Restoring a backup from your favorite Backup Tool (for example Time Machine) will not be enough for Drive files such as
`Google Docs, Google Spreadsheets and Google Slides` since they aren't real files at all when they're sitting in your computer
just pointers to the url of the real file. We need a way to clean and recover those files easily.

Or at least, a way to find the real owners of the files. That's what the script tries to accomplish.

To get this working, you need to do 4 things.

* Make sure you have DART Installed. Follow the instructions here: https://www.dartlang.org/downloads/
	* On mac it's as easy as running `$ brew tap dart-lang/dart && brew install dart`
* Clone this repository: `git clone https://github.com/mobilejazz/drive-clean.git`
* Open a terminal and `cd` into the folder in which the repository is stored locally.
* Run `'pub get'` to retrieve the dependencies req`uired.
* Run the script using: `dart ./bin/drive-clean.dart`

The script will the do it's things and tell you about the whole process.

# License

This text is licensed:

    The MIT License (MIT)

    Copyright (c) 2017 Mobile Jazz

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
