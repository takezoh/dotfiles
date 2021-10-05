;LWin::vkF3sc029  ;Zenkaku/Hankaku [IME off]
;RWin::vkF2sc070  ;Hiragana  [ひらがなキー]
sc07B::Send, {vkF3sc029}
sc079::Send, {vkF2sc070}

#LButton::Send, ^{Click}

sc07B & Space::^Space
sc07B & Tab::#Tab
sc07B & BS::^BS
sc07B & Enter::^Enter
sc07B & a::#a
sc07B & b::^b
sc07B & c::
	if (WinActive("ahk_class mintty") || WinActive("ahk_class CASCADIA_HOSTING_WINDOW_CLASS")) { ; || WinActive("ahk_class ConsoleWindowClass")) {
		Send,^{Insert}
	} else {
		Send,^c
	}
	return
sc07B & d::#d
sc07B & e::#e
sc07B & f::Send, ^f
sc07B & g::#g
sc07B & h::^h
sc07B & i::^i
sc07B & j::^j
sc07B & k::^k
;sc07B & l::Run, rundll32.exe user32.dll,LockWorkStation
sc07B & l::DllCall("LockWorkStation")
sc07B & m::^m
sc07B & n::^n
sc07B & o::^o
sc07B & p::^p
; *<#q::^q
sc07B & q::Send, !{F4}
sc07B & r::^r
sc07B & s::^s
sc07B & t::^t
sc07B & u::^u
sc07B & v::
	if (WinActive("ahk_class mintty") || WinActive("ahk_class CASCADIA_HOSTING_WINDOW_CLASS")) { ; || WinActive("ahk_class ConsoleWindowClass")) {
		Send,+{Insert}
	} else {
		Send,^v
	}
	return
sc07B & w::^w
sc07B & x::^x
sc07B & y::^y
sc07B & z::^z
sc07B & 0::^0
sc07B & 1::^1
sc07B & 2::^2
sc07B & 3::^3
sc07B & 4::^4
sc07B & 5::^5
sc07B & 6::^6
sc07B & 7::^7
sc07B & 8::^8
sc07B & 9::^9

sc079 & Space::#Space
sc079 & Tab::#Tab
sc079 & BS::#BS
sc079 & Enter::#Enter
sc079 & a::#a
sc079 & b::#b
sc079 & c::#c
sc079 & d::#d
sc079 & e::#e
sc079 & f::#f
sc079 & g::#g
sc079 & h::#h
sc079 & i::#i
sc079 & j::#j
sc079 & k::#k
sc079 & l::DllCall("LockWorkStation")
sc079 & m::#m
sc079 & n::#n
sc079 & o::#o
sc079 & p::#p
sc079 & q::#q
sc079 & r::#r
sc079 & s::#s
sc079 & t::#t
sc079 & u::#u
sc079 & v::#v
sc079 & w::#w
sc079 & x::#x
sc079 & y::#y
sc079 & z::#z
sc079 & 0::#0
sc079 & 1::#1
sc079 & 2::#2
sc079 & 3::#3
sc079 & 4::#4
sc079 & 5::#5
sc079 & 6::#6
sc079 & 7::#7
sc079 & 8::#8
sc079 & 9::#9


;*<#Space::^Space
;*<#Tab::#Tab
;*<#BS::^BS
;*<#Enter::^Enter
;*<#a::^a
;*<#b::^b
;*<#c::
;	if (WinActive("ahk_class mintty")) {
;		Send,^{Insert}
;	; } else if (WinActive("ahk_exe vcxsrv.exe") && (WinActive("WinTitle" [ , "take@", "", ""])) {
;		; Send,^{Insert}
;	} else {
;		Send,^c
;	}
;	return
;*<#d::^d
;*<#e::^e
;*<#f::Send, ^f
;*<#g::^g
;*<#h::^h
;*<#i::^i
;*<#j::^j
;*<#k::^k
;*<#l::^l
;*<#m::^m
;*<#n::^n
;*<#o::^o
;*<#p::^p
;; *<#q::^q
;<#q::Send, !{F4}
;*<#r::^r
;*<#s::^s
;*<#t::^t
;*<#u::^u
;*<#v::
;	if (WinActive("ahk_class mintty")) {
;		Send,+{Insert}
;	} else {
;		Send,^v
;	}
;	return
;*<#w::^w
;*<#x::^x
;*<#y::^y
;*<#z::^z
;*<#0::^0
;*<#1::^1
;*<#2::^2
;*<#3::^3
;*<#4::^4
;*<#5::^5
;*<#6::^6
;*<#7::^7
;*<#8::^8
;*<#9::^9
;
;*>#Space::^Space
;*>#Tab::^Tab
;*>#BS::^BS
;*>#Enter::^Enter
;*>#a::^a
;*>#b::^b
;*>#c::^c
;*>#d::^d
;*>#e::^e
;*>#f::^f
;*>#g::^g
;*>#h::^h
;*>#i::^i
;*>#j::^j
;*>#k::^k
;*>#l::^l
;*>#m::^m
;*>#n::^n
;*>#o::^o
;*>#p::^p
;*>#q::^q
;*>#r::^r
;*>#s::^s
;*>#t::^t
;*>#u::^u
;*>#v::^v
;*>#w::^w
;*>#x::^x
;*>#y::^y
;*>#z::^z
;*>#0::^0
;*>#1::^1
;*>#2::^2
;*>#3::^3
;*>#4::^4
;*>#5::^5
;*>#6::^6
;*>#7::^7
;*>#8::^8
;*>#9::^9
