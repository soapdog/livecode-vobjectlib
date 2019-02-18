script "vObjectLib"
/*** Header ***
* vObject library including vCard and iCalendar support
* by Andre Alves Garzia 2005
* 
*************************
* Begin vObject Routines
*************************
*/


/** vObjectBegin **
* Use when creating a vObject, it inserts the begin header.
*
* @param   pObject   Passed by reference. It points to the vObject container that will be changed.
* @param   pType     The object Type, like a "vcard" type will create a "BEGIN:VCARD" header.
*
* @return  nothing.
*/
on vObjectBegin @pObject, pType
  put "BEGIN:" & upper(pType) & CRLF after pObject
end vObjectBegin

/** vObjectEnd **
* Use when ending a vObject, it inserts the end header.
*
* @param   pObject   Passed by reference. It points to the vObject container that will be changed.
* @param   pType     The object Type, like a "vcard" type will create a "END:VCARD" header.
*
* @return  nothing.
*/
on vObjectEnd @pObject, pType
  put "END:" &  upper(pType) & CRLF after pObject
end vObjectEnd

/** vObjectAddProperty **
* Add a property to a vObject. vObject properties are like objects properties from OOP.
*
* @param   pObject     Passed by reference. It points to the vObject container that will be changed.
* @param   pPropName   The property name.
* @param   pPropValue  The property value.
*/
on vObjectAddProperty @pObject, pPropName, pPropValue
  put upper(pPropName) & ":" & pPropValue & CRLF after pObject
end vObjectAddProperty

/** vObjectAddParameter **
* vObjects Properties can have custom parameters associated with them. For Example
* imagine an email prop like this:
* EMAIL:soapdog@mac.com
* you can further refine this prop adding a "prefered" prop and a common name prop.
* EMAIL;TYPE=PREF;CN=Andre Garzia:soapdog@mac.com
* This example is covered in the vCard spec, it's just to show how to tag a property so that it carries
* more usefull information then just the email.
*
* @param   pObject    Passed by reference. It points to the vObject container that will be changed.
* @param   pPropName  The property name that is to be searched. It's a botton-to-up search, so changing a prop will always change the last prop.
* @param   pParamName The parameters name. Parameters might not have a value, in this case they are just there to TAG something.
* @param   param(4)   If present it is assumed as the parameters value.
*/
on vObjectAddParameter @pObject, pPropName, pParamName
  vObjectReverse pObject
  if paramCount() = 4 then
    put ";" & upper(pParamName) & "=" & param(4) into tParamValue
  else
    put ";" & upper(pParamName) into tParamValue
  end if
  put lineoffset(upper(pPropName), pObject) into tPropLocation
  put len(pPropName) into tSize
  put tParamValue after char tSize of line tPropLocation of pObject
  vObjectReverse pObject
end vObjectAddParameter

/** vObjectGroupProperties **
* Properties can be grouped in the vObject/vCard spec much like we group objects in Rev. You give
* a name/label to the group and the props that are to be grouped. As usual, this is done from botton
* up, so it groups the last ocurrences of the props.
*
* @param   pObject    Passed by reference. It points to the vObject container that will be changed.
* @param   pGroupName The label that identify the group.
* @param   param(x)   After param(2) all params are treated as property names.
*/
on vObjectGroupProperties @pObject, pGroupname
  vObjectReverse pObject
  if paramcount() < 4 then
    exit vObjectGroupProperties
  else
    repeat with x = 3 to paramcount()
      put lineoffset(cr & upper(param(x)), cr & pObject) into tPropLocation
      put pGroupName & "." before line tPropLocation of pObject
    end repeat
  end if
  vObjectReverse pObject
end vObjectGroupProperties

/** vObjectReverse **
* An internal function not to be used. This reverses a vObject, this way we can make botton to top searches
* like they were normal searches.
*
* @param   pObject   Passed by reference. It points to the vObject container that will be changed.
*/
on vObjectReverse @pObject
  repeat with x = the number of lines of pObject down to 1
    put line x of pObject & lf after tRetVal
  end repeat
  put tRetVal into pObject
end vObjectReverse


/** vObjectAddBinnary **
* A simple wrapper around vObjectAddProperty and vObjectAddParameter that will add binary content as Base64
* and add a parameter tagging that the content of such prop is binary. Beware that this does not comply with
* vCalendar 2.0 spec, so when adding binary data to iCalendar objects use iCalendar handlers described elsewhere.
*
* @param   pObject   Passed by reference. It points to the vObject container that will be changed.
* @param   pPropName The property name.
* @param   pPropValue The property value, it will be base64 encoded by the handler.
*/
on vObjectAddBinaryProperty @pObject, pPropName, pPropValue
  vObjectAddProperty pObject, pPropName, base64encode(pPropValue)
  vObjectAddParameter pObject, pPropName, "ENCODING", "b"
end vObjectAddBinaryProperty

/** getvObjectProperties **
* A function. It returns all properties names for a given object in a CR delimited chunk.
*
* @param   pObject   The object to be searched.
*
* @return  A CR delimited list with all the properties.
*/
function GetvObjectProperties pObject
  local tProplist
  repeat for each line tProp in pObject
    set the itemdel to ":"
    put the first item of tProp into tPropName
    if tPropName contains "BEGIN" then next repeat
    if tPropName contains "END" then next repeat
    if tPropName contains "." then
      set the itemdel to "."
      put item 2 of tPropName into tPropName
    end if
    if tPropName contains ";" then
      set the itemdel to ";"
      put item 1 of tPropName into tPropName
    end if

    put tPropname & CR after tProplist
  end repeat
  return tPropList
end GetvObjectProperties

/** GetvObjectPropertyValue **
* A function. It returns the value of a given property of an object.
*
* @param  pObject   The object to be searched.
* @param  pPropName The property to find.
*
* @return the value of the property.
*/
function GetvObjectPropertyValue pObject, pPropName
  if pObject contains pPropName then
    put lineoffset(cr & upper(pPropName) & ":", cr & pObject) into tPropLocation
    if tPropLocation is "0" then     put lineoffset(cr & upper(pPropName) & ";", cr & pObject) into tPropLocation
    if tPropLocation is "0" then     put lineoffset("." & upper(pPropName) & ";", pObject) into tPropLocation
    if tPropLocation is "0" then     put lineoffset("." & upper(pPropName) & ":", pObject) into tPropLocation
    
    set the itemdel to ":"
    get line tPropLocation of pObject
    get the item 2 to -1 of it
    return it
  else
    return false
  end if
end GetvObjectPropertyValue

/** getvObjectParamCount **
* A function. like paramCount() it returns the number of parameters in a given property. Good for making
* iterators and loops.
*
* @param  pObject   The object.
* @param  pPropName The property to be found.
*
* @return an integer with the number of parameters to be found in a given prop.
*/
function GetvObjectParamCount pObject, pPropName
  local tParams
  local tRetVal
  put lineoffset(cr & upper(pPropName), cr & pObject) into tPropLocation
  get line tPropLocation of pObject
  get matchText(it, ";(.*):", tParams)
  if it is false then
    return false
  else
    replace ";" with cr in tParams
    repeat for each line tLine in tParams
      if tLine contains "=" then 
        set the itemdel to "="
        put item 1 of tLine & cr after tRetVal
      else
        put tLine  & cr after  tRetVal
      end if
    end repeat
  end if     
  return tRetVal
  
end GetvObjectParamCount

/** getvObjectParam **
* A function. It returns a given parameter from a property.
*
* @param  pObject    The object.
* @param  pPropName  The property containing the object.
* @param  pParamName The parameter to find.
*
* @return the parameter's value.
*/
function getvObjectParam pObject, pPropName, pParamName
  put getvObjectParamcount(pObject, pPropName) into tParamList
  if tParamList contains pParamName then
    put lineoffset(cr & upper(pPropName), cr & pObject) into tPropLocation
    get line tPropLocation of pObject
    get matchText(it, ";(.*):", tParams)
    replace ";" with cr in tParams
    put lineoffset(cr & upper(pParamName), cr & tParams) into tParamLocation
    repeat while tParamLocation is not 0
      get line tParamLocation of tParams
      if it contains "=" then
        set the itemdel to "="
        put item 2 of it & comma after tRetVal
      else
        put true & comma after tRetVal
      end if
      put lineoffset(cr & upper(pParamName), cr & tParams, tParamLocation) into tNextLocation
      if tNextLocation is not 0 then
        put (tNextLocation+ tParamLocation) into tParamLocation
      else
        exit repeat
      end if
    end repeat
  else
    put false into tRetVal
  end if
  if tRetVal is not false then delete char -1 of tRetVal
  return tRetVal
end getvObjectParam

/** vObjectFold **
* This will fold an object, this is needed to sharing objects to ensure the 75 chars line limitation.
*
* @param   pObject    The object to be folded.
*/
on vObjectFold @pObject
repeat with x = 1 to the number of lines in pObject
    put line x of pObject into tLine
    if len(tLine) > 75 then
      put LF & " " after char 75 of line x of pObject
    end if
  end repeat
  return true
end vObjectFold

/** vObjectUnfold **
* This will pick a serialized object and unfold it so that each line corresponds to one and only one prop.
* You must unfold an object before start working with it.
*
* @param   pObject   The object to be unfolded.
*/
on vObjectUnFold @pObject
  replace LF & " " with empty in pObject
end vObjectUnFold



/** vObjectCount **
* A function. It returns the number of objects of a given type inside a vObject container. For example it can
* return the number of contacts inside a vCard object.
*
* @param   pObjectType   The object Type (Ie: vCard, iCalendar, vEvent)
* @param   pObject       The object container.
*
* @return  The number of objects inside the vObject container.
*/
function vObjectCount pObjectType, pObject
  put vObjectSplit(pObjectType, pObject) into tArrayA
  return the number of lines in the keys of tArrayA
end vObjectCount

/** vObjectGet **
* A function. It returns a vObject inside a vObject container at a given index. For example you can ask for the 
* third contact inside a vCard container with 'put vObjectGet("vCard", tAllCards, 3) into tThirdCard'
*
* @param   pObjectType   The object type to be acquired (Ie: vCard)
* @param   pObject       The object container.
* @param   pIndex        The index.
*
* @return  A vObject at a given index.
*/
function vObjectGet pObjectType, pObject, pIndex
  if vObjectCount(pObjectType, pObject) < pIndex then
    return false
  else
    put vObjectSplit(pObjectType, pObject) into tRetValA
    return tRetValA[pIndex]
  end if
end vObjectGet



/** vObjectSplit **
* A function. It returns an array of vObjects. You can use 'put vObjectSplit("vCard", tAllCards) into tArrayA'
* then access the vCards as tArrayA[x].
*
* @param   pObjectType   The object type to be acquired (Ie: vCard)
* @param   pObject       The object container.
*
* @return  An array of vObjects
*/
function vObjectSplit pObjectType, pObject
  put "BEGIN:" & pObjectType into tHeader
  put "END:" & pObjectType into tFooter
  repeat with x = 1 to the number of lines in pObject
    put line x of pObject into tLine
    if tLine contains tHeader then put x into tBeginBlock
    if tLine contains tFooter then put x into tEndBlock
    if tEndBlock is not empty then
      put line tBeginBlock to tEndBlock of pObject & numToChar(4) after tRetVal
      put empty into tEndBlock
      put empty into tBeginBlock
    end if
  end repeat
  delete char -1 of tRetVal
  split tRetVal by numToChar(4)
  return tRetVal
end vObjectSplit


/*** Header ***
*
***********************
* Begin vCard routines
***********************
*/

/** vCardAddFullName **
* from vCard 2.0 spec. Adds a full name property to a contact.
*
* @param   pObject   the vObject/vCard, passed by Reference.
* @param   pValue    The full name.
*/
on vCardAddFullName @pObject, pValue
  vObjectAddProperty pObject, "FN", pValue
end vCardAddFullName

/** vCardAddNickname **
* from vCard 2.0 spec. Adds a Nickname property to a contact.
*
* @param   pObject   the vObject/vCard, passed by Reference.
* @param   pValue    The Nickname.
*/
on vCardAddNickname @pObject, pValue
  vObjectAddProperty pObject, "NICKNAME", pValue
end vCardAddNickname

/** vCardAddPhoto **
* from vCard 2.0 spec. Adds a photo property to a contact. This property is a binary one, it will be tagged and base64 
* encoded as per vCard 2.0 spec.
*
* @param   pObject   the vObject/vCard, passed by Reference.
* @param   pValue    The photo data.
* @param   ptype     MIME type of the photo (Ie: image/jpeg)
*/
on vCardAddPhoto @pObject, pValue, pType
  vObjectAddBinaryProperty pObject, "PHOTO", pValue
  vObjectAddParameter pObject, "PHOTO", "TYPE", pType
end vCardAddPhoto

/** vCardAddPhotoURL **
* from vCard 2.0 spec. Adds a photo property to a contact. This property is a URL one, it points to a URL with the photo
*
* @param   pObject   the vObject/vCard, passed by Reference.
* @param   pValue    The photo file URL.
*/
on vCardAddPhotoURL @pObject, pValue
  vObjectAddBinaryProperty pObject, "PHOTO", pValue
  vObjectAddParameter pObject, "PHOTO", "VALUE", "uri"
end vCardAddPhotoURL

/** vCardAddBirthday **
* from vCard 2.0 spec. Adds a Birthday property to a contact.
*
* @param   pObject   the vObject/vCard, passed by Reference.
* @param   pValue    The Birthday.
*/
on vCardAddBirthday @pObject, pValue
  vObjectAddProperty pObject, "BDAY", pValue
end vCardAddBirthday


/** vCardAddName **
* from vCard 2.0 spec. Adds a Name property to a contact. It's full of params and all must be present.
* the params corresponds, in sequence, to the Family Name, Given Name, Additional Names, Honorific
* Prefixes, and Honorific Suffixes. The text components are separated by the SEMI-COLON character 
* (ASCII decimal 59). Individual text components can include multiple text values (e.g., multiple
* Additional Names) separated by the COMMA character (ASCII decimal 44). THIS PROP MUST BE PRESENT!!!!
*
* @param   pObject     the vObject/vCard, passed by Reference.
* @param   param(x)    The params for the name.
*/
on vCardAddName @pObject     ## MUST BE PRESENT ##
  repeat with x = 2 to 6
    put param(x) & ";" after tStructuredName
  end repeat
  
  delete char -1 of tStructuredName
  vObjectAddProperty pObject, "N", tStructuredName
end vCardAddName

/** vCardAddName **
* from vCard 2.0 spec. Adds a address property to a contact. It's full of params and all must be present.
* the params in their corresponding position. The structured type value corresponds, in sequence, to the post
* office box; the extended address; the street address; the locality (e.g., city); the region (e.g., state or
* province); the postal code; the country name. When a component value is missing, the associated component 
* separator MUST still be specified. THIS PROP MUST BE PRESENT!!!!
*
* @param   pObject     the vObject/vCard, passed by Reference.
* @param   param(x)    The params for the address.
*/
on vCardAddaddress @pObject     ## MUST BE PRESENT ##
  repeat with x = 2 to 7
    put param(x) & ";" after tStructuredAddress
  end repeat
  
  delete char -1 of tStructuredAddress
  replace "," with "\," in tStructuredAddress
  
  vObjectAddProperty pObject, "ADR", tStructuredAddress
  if param(8) is not empty then
    vObjectAddParameter pObject, "ADR", "TYPE", param(8)
  end if
end vCardAddaddress

/** vCardAddLabel **
* from vCard 2.0 spec. Adds a Label property to a contact.
* 
* @param   pObject     the vObject/vCard, passed by Reference.
* @param   pLabel      The params for the label.
*/
on vCardAddLabel @pObject
  put param(2) into tLabel
  replace "," with "\," in tLabel
  vObjectAddProperty pObject, "LABEL", tLabel
  if param(3) is not empty then
    vObjectAddParameter pObject, "LABEL", "TYPE", param(3)
  end if
end vCardAddLabel

on vCardAddPhone @pObject
  put param(2) into tLabel
  replace "," with "\," in tLabel
  vObjectAddProperty pObject, "TEL", tLabel
  if param(3) is not empty then
    vObjectAddParameter pObject, "TEL", "TYPE", param(3)
  end if
end vCardAddPhone

on vCardAddEmail @pObject
  put param(2) into tLabel
  replace "," with "\," in tLabel
  vObjectAddProperty pObject, "EMAIL", tLabel
  if param(3) is not empty then
    vObjectAddParameter pObject, "EMAIL", "TYPE", param(3)
  else
    vObjectAddParameter pObject, "EMAIL", "TYPE", "internet"
  end if
end vCardAddEmail

on vCardAddMailer @pObject, pValue
  vObjectAddProperty pObject, "MAILER", pValue
end vCardAddMailer


on vCardAddTimezone @pObject, pValue
    vObjectAddProperty pObject, "TZ", pValue
end vCardAddTimezone

on vCardAddGeo @pObject, pLat, pLon
    vObjectAddProperty pObject, "GEO", (pLat & ";" & pLon)
end vCardAddGeo 


on vCardAddTitle @pObject, pValue
  replace "," with "\," in pValue
  vObjectAddProperty pObject, "TITLE", pValue
end vCardAddTitle

on vCardAddRole @pObject, pValue
    vObjectAddProperty pObject, "ROLE", pValue
end vCardAddRole



on vCardAddLogo @pObject, pValue, pType
  vObjectAddBinaryProperty pObject, "LOGO", pValue
  vObjectAddParameter pObject, "LOGO", "TYPE", pType
end vCardAddLogo

on vCardAddLogoURL @pObject, pValue
  vObjectAddBinaryProperty pObject, "LOGO", pValue
  vObjectAddParameter pObject, "LOGO", "VALUE", "uri"
end vCardAddLogoURL


on vCardAddAgent @pObject, pValue
  replace cr with "\n" in pValue
  vObjectAddProperty pObject, "AGENT", pValue
end vCardAddAgent


on vCardAddOrg @pObject
  repeat with x = 2 to paramcount()
    put param(x) into tValue
    replace "," with "\," in tValue
    put tValue & ";" after tStructuredValue
  end repeat
  delete char -1 of tStructuredValue
  vObjectaddProperty pObject, "ORG", tStructuredValue
end vCardAddOrg

on vCardAddCategories @pObject
  repeat with x = 2 to paramcount()
    put param(x) into tValue
    replace "," with "\," in tValue
    put tValue & "," after tStructuredValue
  end repeat
  delete char -1 of tStructuredValue
  vObjectaddProperty pObject, "CATEGORY", tStructuredValue
end vCardAddCategories

on vCardAddNote @pObject, pValue
  replace cr with "\n" in pValue
  replace "," with "\," in pValue
  vObjectAddProperty pObject, "NOTE", pValue
end vCardAddNote

on vCardAddProdID @pObject, pValue
  put format("-//$s//Revolution/MetaCard//EN", pValue) into tValue
  vObjectAddProperty pObject, "PRODID", tValue
end vCardAddProdID

on vCardAddRevision @pObject, pValue
    vObjectAddProperty pObject, "REV", pValue
end vCardAddRevision

on vCardAddSortString @pObject, pValue
    vObjectAddProperty pObject, "SORT-STRING", pValue
end vCardAddSortString


on vCardAddSound @pObject, pValue, pType
  vObjectAddBinaryProperty pObject, "SOUND", pValue
  vObjectAddParameter pObject, "SOUND", "TYPE", pType
end vCardAddSound

on vCardAddSoundURL @pObject, pValue
  vObjectAddBinaryProperty pObject, "SOUND", pValue
  vObjectAddParameter pObject, "SOUND", "VALUE", "uri"
end vCardAddSoundURL

on vCardAddUID @pObject, pValue
    vObjectAddProperty pObject, "UID", pValue
end vCardAddUID

on vCardAddURL @pObject, pValue
    vObjectAddProperty pObject, "URL", pValue
end vCardAddURL

on vCardAddVersion @pObject, pValue
  ## This lib corresponds to version 3
  vObjectAddProperty pObject, "VERSION", pValue
end vCardAddVersion


on vCardAddClass @pObject, pValue
    vObjectAddProperty pObject, "CLASS", upper(pValue)
end vCardAddClass

on vCardAddKey @pObject, pValue
  vObjectAddBinaryProperty pObject, "KEY", pValue
  if param(3) is not empty then
    vObjectAddParameter pObject, "KEY", "TYPE", param(3)
  end if
end vCardAddKey

on vCardBegin @pObject
  vObjectBegin pObject, "VCARD"
end vCardBegin

on vCardEnd @pObject
  vObjectEnd pObject, "VCARD"
end vCardEnd


on vCardSerialize @pObject
  if line 1 of pObject is not "BEGIN:VCARD" then
    return "Error: card header wrong. forgot vCardBegin?"
  end if
  if line -1 of pObject is not "END:VCARD" then
    return "Error: card footer wrong. forgot vCardEnd?"
  end if
   
  get getvObjectPropertyValue(pObject, "VERSION")
  if it is false then
    vCardAddVersion pObject, "3"
  end if
  get getvObjectPropertyValue(pObject, "FN")
  if it is false then
    return "Error: Required prop full name. use vCardAddFullName to add full name."
  end if
  get getvObjectPropertyValue(pObject, "N")
  if it is false then
    return "Error: Required prop name. use vCardAddName to add name."
  end if
  repeat with x = 1 to the number of lines in pObject
    put line x of pObject into tLine
    if len(tLine) > 75 then
      put LF & " " after char 75 of line x of pObject
    end if
  end repeat
  return true
end vCardSerialize

on vCardUnserialize @pObject
  replace LF & " " with empty in pObject
end vCardUnserialize



/**************************
* Begin iCalendar Routines
***************************
*/

on icCalendarBegin @pObject
  vObjectBegin pObject, "VCALENDAR"
end icCalendarBegin

on icCalendarEnd @pObject
  vObjectEnd pObject, "VCALENDAR"
end icCalendarEnd

on icAlarmBegin @pObject
  vObjectBegin pObject, "VALARM"
end icAlarmBegin

on icAlarmEnd @pObject
  vObjectEnd pObject, "VALARM"
end icAlarmEnd

on icTimezoneBegin @pObject
  vObjectBegin pObject, "VTIMEZONE"
end icTimezoneBegin

on icTimezoneEnd @pObject
  vObjectEnd pObject, "VTIMEZONE"
end icTimezoneEnd

on icFreeBusyBegin @pObject
  vObjectBegin pObject, "VFREEBUSY"
end icFreeBusyBegin

on icFreeBusyEnd @pObject
  vObjectEnd pObject, "VFREEBUSY"
end icFreeBusyEnd

on icEventBegin @pObject
  vObjectBegin pObject, "VEVENT"
end icEventBegin

on icEventEnd @pObject
  vObjectEnd pObject, "VEVENT"
end icEventEnd

on icJournalBegin @pObject
  vObjectBegin pObject, "VJOURNAL"
end icJournalBegin

on icJournalEnd @pObject
  vObjectEnd pObject, "VJOURNAL"
end icJournalEnd

on icTodoBegin @pObject
  vObjectBegin pObject, "VTODO"
end icTodoBegin

on icTodoEnd @pObject
  vObjectEnd pObject, "VTODO"
end icTodoEnd

on icAddParam @pObject, pProp, pParam, pValue
  vObjectAddParameter pObject, pProp, pParam, pValue
end icAddParam

on icAddAlternativeRep @pObject, pProp, pValue
  icAddParam pObject, pProp, "ALTREP", pValue
end icAddAlternativeRep

on icAddCommonName @pObject, pProp, pValue
  icAddParam pObject, pProp, "CN", pValue
end icAddCommonName

on icAddCalendarUserType @pObject, pProp, pValue
  icAddParam pObject, pProp, "CUTYPE", pValue
end icAddCalendarUserType


on icAddDelegator @pObject, pProp, pValue
  icAddParam pObject, pProp, "DELEGATED-FROM", pValue
end icAddDelegator

on icAddDelegatee @pObject, pProp, pValue
  icAddParam pObject, pProp, "DELEGATED-TO", pValue
end icAddDelegatee

on icAddDirectory @pObject, pProp, pValue
  icAddParam pObject, pProp, "DIR", pValue
end icAddDirectory


on icAddEncoding @pObject, pProp, pValue
  icAddParam pObject, pProp, "ENCODING", pValue
end icAddEncoding


on icAddFormatType @pObject, pProp, pValue
  icAddParam pObject, pProp, "FMTTYPE", pValue
end icAddFormatType

on icAddFreeBusyTimeType @pObject, pProp, pValue
  icAddParam pObject, pProp, "FBTYPE", pValue
end icAddFreeBusyTimeType

on icAddLanguage @pObject, pProp, pValue
  icAddParam pObject, pProp, "LANGUAGE", pValue
end icAddLanguage


on icAddMember @pObject, pProp, pValue
  icAddParam pObject, pProp, "MEMBER", pValue
end icAddMember


on icAddParticipationStatus @pObject, pProp, pValue
  icAddParam pObject, pProp, "PARTSTAT", pValue
end icAddParticipationStatus

on icAddRange @pObject, pProp, pValue
  icAddParam pObject, pProp, "RANGE", pValue
end icAddRange

on icAddRelation @pObject, pProp, pValue
  icAddParam pObject, pProp, "RELATED", pValue
end icAddRelation

on icAddRelationshipType @pObject, pProp, pValue
  icAddParam pObject, pProp, "RELTYPE", pValue
end icAddRelationshipType

on icAddRole @pObject, pProp, pValue
  icAddParam pObject, pProp, "ROLE", pValue
end icAddRole

on icAddRSVP @pObject, pProp, pValue
  icAddParam pObject, pProp, "RSVP", pValue
end icAddRSVP

on icAddSentBy @pObject, pProp, pValue
  icAddParam pObject, pProp, "SENT-BY", pValue
end icAddSentBy

on icAddTimeZoneID @pObject, pProp, pValue
  icAddParam pObject, pProp, "TZID", pValue
end icAddTimeZoneID

on icAddValue @pObject, pProp, pValue
  icAddParam pObject, pProp, "VALUE", pValue
end icAddValue

/*
* Begin iCalendar Prop Routines
*/

on icCalendarScale @pObject, pValue
  vObjectAddProperty pObject, "CAL-SCALE", pValue
end icCalendarScale

on icCalendarMethod @pObject, pValue
  vObjectAddProperty pObject, "METHOD", pValue
end icCalendarMethod

on icCalendarProdID @pObject, pValue
  vObjectAddProperty pObject, "PRODID", pValue
end icCalendarProdID

on icCalendarVersion @pObject, pValue
  vObjectAddProperty pObject, "VERSION", pValue
end icCalendarVersion

on icAddAttachment @pObject, pBase64Value
  vObjectAddProperty pObject, "ATTACH", pBase64Value
  icAddEncoding pObject, "ATTACH", "BASE64"
  icAddValue pObject, "ATTACH", "BINARY"
end icAddAttachment

on icAddAttachmentURL @pObject, pURL
  vObjectAddProperty pObject, "ATTACH", pURL
end icAddAttachmentURL


on icAddCategories @pObject
  repeat with x = 2 to paramcount()
    put param(x) into tValue
    replace "," with "\," in tValue
    put tValue & "," after tStructuredValue
  end repeat
  delete char -1 of tStructuredValue
  vObjectaddProperty pObject, "CATEGORIES", tStructuredValue
end icAddCategories


on icAddClass @pObject, pValue
  vObjectAddProperty pObject, "CLASS", pValue
end icAddClass

on icAddComment @pObject, pValue
  replace CRLF with "\n" in pValue
  replace CR with "\n" in pValue
  replace LF with "\n" in pValue
  vObjectAddProperty pObject, "COMMENT", pValue
end icAddComment

on icAddDescription @pObject, pValue
  replace CRLF with "\n" in pValue
  replace CR with "\n" in pValue
  replace LF with "\n" in pValue
  vObjectAddProperty pObject, "DESCRIPTION", pValue
end icAddDescription

on icAddGeo @pObject, pValue
  vObjectAddProperty pObject, "GEO", pValue
end icAddGeo


on icAddLocation @pObject, pValue
  vObjectAddProperty pObject, "LOCATION", pValue
end icAddLocation

on icAddPercentComplete @pObject, pValue
  vObjectAddProperty pObject, "PERCENT-COMPLETE", pValue
end icAddPercentComplete

on icAddPriority @pObject, pValue
  vObjectAddProperty pObject, "PRIORITY", pValue
end icAddPriority

on icAddResources @pObject, pValue
  vObjectAddProperty pObject, "RESOURCES", pValue
end icAddResources

on icAddStatus @pObject, pValue
  vObjectAddProperty pObject, "STATUS", pValue
end icAddStatus

on icAddSummary @pObject, pValue
  vObjectAddProperty pObject, "SUMMARY", pValue
end icAddSummary

on icAddDateTimeCompleted @pObject, pValue
  vObjectAddProperty pObject, "COMPLETED", pValue
end icAddDateTimeCompleted

on icAddDateTimeEnd @pObject, pValue
  vObjectAddProperty pObject, "DTEND", pValue
end icAddDateTimeEnd

on icAddDateTimeStart @pObject, pValue
  vObjectAddProperty pObject, "DTSTART", pValue
end icAddDateTimeStart

on icAddDateTimeStamp @pObject, pValue
  vObjectAddProperty pObject, "DTSTAMP", pValue
end icAddDateTimeStamp

on icAddDateTimeDue @pObject, pValue
  vObjectAddProperty pObject, "DUE", pValue
end icAddDateTimeDue

on icAddDuration @pObject, pValue
  vObjectAddProperty pObject, "DURATION", pValue
end icAddDuration

on icAddFreeBusy @pObject, pValue
  vObjectAddProperty pObject, "FREEBUSY", pValue
end icAddFreeBusy

on icAddTransparency @pObject, pValue
  vObjectAddProperty pObject, "TRANSP", pValue
end icAddTransparency

on icAddTimeZone @pObject, pValue
  vObjectAddProperty pObject, "TZID", pValue
end icAddTimeZone

on icAddTimeZoneName @pObject, pValue
  vObjectAddProperty pObject, "TZNAME", pValue
end icAddTimeZoneName

on icAddTimeZoneOffSetFrom @pObject, pValue
  vObjectAddProperty pObject, "TZOFFSETFROM", pValue
end icAddTimeZoneOffSetFrom

on icAddTimeZoneOffSetTo @pObject, pValue
  vObjectAddProperty pObject, "TZOFFSETTO", pValue
end icAddTimeZoneOffSetTo

on icAddTimeZoneURL @pObject, pValue
  vObjectAddProperty pObject, "TZURL", pValue
end icAddTimeZoneURL


on icAddAttendee @pObject, pValue
  vObjectAddProperty pObject, "ATTENDEE", pValue
end icAddAttendee

on icAddOrganizer @pObject, pValue
  vObjectAddProperty pObject, "ORGANIZER", pValue
end icAddOrganizer

function icDuration
  if params() >= 2 then
    repeat with x = 1 to the paramcount
      put param(x) into tDurationItem
      if tDurationItem is "-" then
        put "-" into tSign
      end if
      set the itemdel to " "
      put item 1 of tDurationItem into tAmount
      put item 2 of tDurationItem into tType
      switch toLower(tType)
      case "day"
      case "days"
        put tAmount & "D" after tRetVal
        break
      case "minute"
      case "minutes"
        put tAmount & "M" after tRetVal
        break
      case "week"
      case "weeks"
        put tAmount & "W" after tRetVal
        break
      default
      case "hour"
      case "hours"
        put tAmount & "H" after tRetVal
        break
      case "secs"
      case "second"
      case "seconds"
        put tAmount & "S" after tRetVal
        break
      end switch
    end repeat
    return tSign & "P" & tRetVal
  end if
end icDuration



function icConvertDate pDate
  convert pDate to dateitems
  put item 1 of pDate into tYear
  put item 2 of pDate into tMonth
  if len(tMonth) is 1 then put "0" & tMonth into tMonth
  put item 3 of pDate into tDate
  if len(tDate) is 1 then put "0" & tDate into tDate
  put item 4 of pDate into tHours
  if len(tHours) is 1 then put "0" & tHours into tHours
  put item 5 of pDate into tMinutes
  if len(tMinutes) is 1 then put "0" & tMinutes into tMinutes
  put item 6 of pDate into tSeconds
  if len(tSeconds) is 1 then put "0" & tSeconds into tSeconds
  put tYear & tMonth & tDate & "T" & tHours & tMinutes & tSeconds into tRetVal
  return tRetVal 
end icConvertDate


on icAddContact @pObject, pValue
  replace CRLF with "\n" in pValue
  replace CR with "\n" in pValue
  replace LF with "\n" in pValue
  vObjectAddProperty pObject, "CONTACT", pValue
end icAddContact

on icAddRecurrenceID @pObject, pValue
  vObjectAddProperty pObject, "RECURRENCE-ID", pValue
end icAddRecurrenceID

on icAddRelatedTo @pObject, pValue
  vObjectAddProperty pObject, "RELATED-TO", pValue
end icAddRelatedTo

on icAddURL @pObject, pValue
  vObjectAddProperty pObject, "URL", pValue
end icAddURL

on icAddUID @pObject, pValue
  vObjectAddProperty pObject, "UID", pValue
end icAddUID


on icAddRRULE @pObject, pValue
  vObjectAddProperty pObject, "RRULE", pValue
end icAddRRULE

on icAddRDATE @pObject, pValue
  vObjectAddProperty pObject, "RDATE", pValue
end icAddRDATE

on icAddEXRULE @pObject, pValue
  vObjectAddProperty pObject, "EXRULE", pValue
end icAddEXRULE

on icAddEXDATE @pObject, pValue
  vObjectAddProperty pObject, "EXDATE", pValue
end icAddEXDATE

// Begin Recur Param routines

on icAddCount @pObject, pProp, pValue
  icAddParam pObject, pProp, "COUNT", pValue
end icAddCount

on icAddInterval @pObject, pProp, pValue
  icAddParam pObject, pProp, "INTERVAL", pValue
end icAddInterval

on icAddUntil @pObject, pProp, pValue
  icAddParam pObject, pProp, "UNTIL", pValue
end icAddUntil


on icAddFrequency @pObject, pProp, pValue
  icAddParam pObject, pProp, "FREQ", pValue
end icAddFrequency

on icAddByMonth @pObject, pProp, pValue
  icAddParam pObject, pProp, "BYMONTH", pValue
end icAddByMonth

on icAddByDate @pObject, pProp, pValue
  icAddParam pObject, pProp, "BYDATE", pValue
end icAddByDate

on icAddBySecond @pObject, pProp, pValue
  icAddParam pObject, pProp, "BYSECOND", pValue
end icAddBySecond

on icAddByDay @pObject, pProp, pValue
  icAddParam pObject, pProp, "BYDAY", pValue
end icAddByDay

on icAddByMinute @pObject, pProp, pValue
  icAddParam pObject, pProp, "BYMINUTE", pValue
end icAddByMinute

on icAddByHour @pObject, pProp, pValue
  icAddParam pObject, pProp, "BYHOUR", pValue
end icAddByHour

on icAddBYMONTHDAY @pObject, pProp, pValue
  icAddParam pObject, pProp, "BYMONTHDAY", pValue
end icAddBYMONTHDAY

on icAddBYYEARDAY @pObject, pProp, pValue
  icAddParam pObject, pProp, "BYYEARDAY", pValue
end icAddBYYEARDAY


on icAddBYWEEKNO @pObject, pProp, pValue
  icAddParam pObject, pProp, "BYWEEKNO", pValue
end icAddBYWEEKNO


on icAddBYMONTH @pObject, pProp, pValue
  icAddParam pObject, pProp, "BYMONTH", pValue
end icAddBYMONTH


on icAddBYSETPOS @pObject, pProp, pValue
  icAddParam pObject, pProp, "BYSETPOS", pValue
end icAddBYSETPOS

on icAddWeekday @pObject, pProp, pValue
  icAddParam pObject, pProp, "WKST", pValue
end icAddWeekday

// begin alarm routines


on icAddAlarmAction @pObject, pValue
  vObjectAddProperty pObject, "ACTION", pValue
end icAddAlarmAction

on icAddAlarmRepeatCount @pObject, pValue
  vObjectAddProperty pObject, "REPEAT", pValue
end icAddAlarmRepeatCount

on icAddAlarmDuration @pObject, pValue
  vObjectAddProperty pObject, "DURATION", pValue
end icAddAlarmDuration

on icAddAlarmTrigger @pObject, pValue
  vObjectAddProperty pObject, "TRIGGER", pValue
end icAddAlarmTrigger

on icAddCreationDate @pObject, pValue
  vObjectAddProperty pObject, "CREATED", pValue
end icAddCreationDate

on icAddLastModDate @pObject, pValue
  vObjectAddProperty pObject, "LAST-MODIFIED", pValue
end icAddLastModDate

on icAddSequence @pObject, pValue
  vObjectAddProperty pObject, "SEQUENCE", pValue
end icAddSequence

on icAddRequestStatus @pObject, pValue
  vObjectAddProperty pObject, "REQUEST-STATUS", pValue
end icAddRequestStatus
