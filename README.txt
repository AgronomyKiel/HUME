-----------------------------------------------------------------

                         TmdURLLabel

-----------------------------------------------------------------

This package is in version 1.2 and given free the 5th november 1997.

Latest version will always be avalible at :
http://www.djernaes.dk/martin

The Package gives one class (one components) to use within
the Delphi 2.0 enviroment (eventually also 3.0 and C++ Builder,
but that is not testet).

-----------------------------------------------------------------
Components :
  TmdURLLabel :

  A web link component. When LabelType is set to AUTO, it makes
  it self look like a normal label, when no internet transport
  is avalible. When a internet transport (web browser for URL and
  MAPI for e-mail's) the label looks like a URL in your web browser.
  
  The check for a web browser is done by testing if any program 
  is connected to both the .htm and .html extensions.
  The check for a e-mail program, is done by checking if the MAPI
  dll is reachable.

-----------------------------------------------------------------
Note :
  I have only testet with Netscape as web browser, but it should
  work with any Windows 95 / NT (TM) web browser.
  (I'm told it works with IE4.0)

  The MAPI is check is not really testet, because I only have 
  computers with MAPI installed.

  If a MAPI program (like Microsoft Messaging / Exchange) is
  installed without support for e-mail, the label will still
  expect that it can send a e-mail (via MAPI). It does only know
  if MAPI is there, not if it can send e-mail via the internet.

-----------------------------------------------------------------
Legal issues :
Copyright © 1997 by Martin Djernæs <martin@djernaes.dk>

This software is provided as it is, without any kind of warranty
given. The author can not be held responsible for any kind of
damage, problems etc. from using this product.

You may use this software in any kind of development, including
comercial, and redistribute it freely, under the following
restrictions:

1. The origin of this software may not be mispresented, you must
   not claim that you wrote the original software. If you use
   this software in any kind of product, it would be appreciated
   that in a information box, or in the documentation would be
   an acknowledgmnent like this
          Parts copyright © 1997 by Martin Djernæs

2. You may not have any income from distributing this source
   to other developers. When you use this product in a comercial
   package, the source may not be charged seperatly.

3. This notice may not be removed from the source, when distributing
   such. When distributing a comercial package, where the source
   also is avalible, this notice should also follow the package, even
   you choose not to make my source avalible.

                                                               - MD97