LWin::vkF3sc029  ;Zenkaku/Hankaku [IME off]
RWin::vkF2sc070  ;Hiragana  [ひらがなキー]
sc07B::vkF3sc029
sc079::vkF2sc070

#LButton::Send, ^{Click}

*<#Space::^Space
*<#Tab::#Tab
*<#BS::^BS
*<#Enter::^Enter
*<#a::^a
*<#b::^b
*<#c::
	if (WinActive("ahk_class mintty")) {
		Send,^{Insert}
	; } else if (WinActive("ahk_exe vcxsrv.exe") && (WinActive("WinTitle" [ , "take@", "", ""])) {
		; Send,^{Insert}
	} else {
		Send,^c
	}
	return
*<#d::^d
*<#e::^e
*<#f::Send, ^f
*<#g::^g
*<#h::^h
*<#i::^i
*<#j::^j
*<#k::^k
*<#l::^l
*<#m::^m
*<#n::^n
*<#o::^o
*<#p::^p
; *<#q::^q
<#q::Send, !{F4}
*<#r::^r
*<#s::^s
*<#t::^t
*<#u::^u
*<#v::
	if (WinActive("ahk_class mintty")) {
		Send,+{Insert}
	} else {
		Send,^v
	}
	return
*<#w::^w
*<#x::^x
*<#y::^y
*<#z::^z
*<#0::^0
*<#1::^1
*<#2::^2
*<#3::^3
*<#4::^4
*<#5::^5
*<#6::^6
*<#7::^7
*<#8::^8
*<#9::^9

*>#Space::^Space
*>#Tab::^Tab
*>#BS::^BS
*>#Enter::^Enter
*>#a::^a
*>#b::^b
*>#c::^c
*>#d::^d
*>#e::^e
*>#f::^f
*>#g::^g
*>#h::^h
*>#i::^i
*>#j::^j
*>#k::^k
*>#l::^l
*>#m::^m
*>#n::^n
*>#o::^o
*>#p::^p
*>#q::^q
*>#r::^r
*>#s::^s
*>#t::^t
*>#u::^u
*>#v::^v
*>#w::^w
*>#x::^x
*>#y::^y
*>#z::^z
*>#0::^0
*>#1::^1
*>#2::^2
*>#3::^3
*>#4::^4
*>#5::^5
*>#6::^6
*>#7::^7
*>#8::^8
*>#9::^9
