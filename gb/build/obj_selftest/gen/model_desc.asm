;--------------------------------------------------------
; File Created by SDCC : free open source ISO C Compiler
; Version 4.5.1 #15267 (Linux)
;--------------------------------------------------------
	.module model_desc
	
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _tok_len
	.globl _tok_str
	.globl _dot_entries
	.globl _layer_cfg
	.globl _mat_lm
	.globl _mat_w2
	.globl _mat_w1
	.globl _mat_wo
	.globl _mat_wv
	.globl _mat_wk
	.globl _mat_wq
;--------------------------------------------------------
; special function registers
;--------------------------------------------------------
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	.area _DATA
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	.area _INITIALIZED
;--------------------------------------------------------
; absolute external ram data
;--------------------------------------------------------
	.area _DABS (ABS)
;--------------------------------------------------------
; global & static initialisations
;--------------------------------------------------------
	.area _HOME
	.area _GSINIT
	.area _GSFINAL
	.area _GSINIT
;--------------------------------------------------------
; Home
;--------------------------------------------------------
	.area _HOME
	.area _HOME
;--------------------------------------------------------
; code
;--------------------------------------------------------
	.area _CODE
	.area _CODE
_mat_wq:
	.dw _L0_wq
	.dw _L0_wq_sq
	.db #0x01	; 1
	.dw _L1_wq
	.dw _L1_wq_sq
	.db #0x01	; 1
_mat_wk:
	.dw _L0_wk
	.dw _L0_wk_sq
	.db #0x01	; 1
	.dw _L1_wk
	.dw _L1_wk_sq
	.db #0x01	; 1
_mat_wv:
	.dw _L0_wv
	.dw _L0_wv_sq
	.db #0x01	; 1
	.dw _L1_wv
	.dw _L1_wv_sq
	.db #0x01	; 1
_mat_wo:
	.dw _L0_wo
	.dw _L0_wo_sq
	.db #0x01	; 1
	.dw _L1_wo
	.dw _L1_wo_sq
	.db #0x01	; 1
_mat_w1:
	.dw _L0_w1
	.dw _L0_w1_sq
	.db #0x01	; 1
	.dw _L1_w1
	.dw _L1_w1_sq
	.db #0x01	; 1
_mat_w2:
	.dw _L0_w2
	.dw _L0_w2_sq
	.db #0x01	; 1
	.dw _L1_w2
	.dw _L1_w2_sq
	.db #0x02	; 2
_mat_lm:
	.dw _lm_head
	.dw _lm_head_sq
	.db #0x02	; 2
_layer_cfg:
	.db #0x07	; 7
	.db #0x07	; 7
	.db #0x07	; 7
	.db #0x08	; 8
	.db #0x04	; 4
	.db #0x07	; 7
	.db #0x08	; 8
	.db #0x05	; 5
	.dw #0x0100
	.db #0x07	; 7
	.db #0x07	; 7
	.db #0x07	; 7
	.db #0x08	; 8
	.db #0x04	; 4
	.db #0x07	; 7
	.db #0x07	; 7
	.db #0x04	; 4
	.dw #0x0100
_dot_entries:
	.dw _dot_from_0
	.dw _dot_from_16
	.dw _dot_from_32
	.dw _dot_from_48
	.dw _dot_from_64
	.dw _dot_from_80
_tok_str:
	.dw __str_0
	.dw __str_0
	.dw __str_0
	.dw __str_0
	.dw __str_1
	.dw __str_2
	.dw __str_3
	.dw __str_4
	.dw __str_5
	.dw __str_6
	.dw __str_7
	.dw __str_8
	.dw __str_9
	.dw __str_10
	.dw __str_11
	.dw __str_12
	.dw __str_13
	.dw __str_14
	.dw __str_15
	.dw __str_16
	.dw __str_17
	.dw __str_18
	.dw __str_19
	.dw __str_20
	.dw __str_21
	.dw __str_22
	.dw __str_23
	.dw __str_24
	.dw __str_25
	.dw __str_26
	.dw __str_27
	.dw __str_28
	.dw __str_29
	.dw __str_30
	.dw __str_31
	.dw __str_32
	.dw __str_33
	.dw __str_34
	.dw __str_35
	.dw __str_36
	.dw __str_37
	.dw __str_38
	.dw __str_39
	.dw __str_40
	.dw __str_41
	.dw __str_42
	.dw __str_43
	.dw __str_44
	.dw __str_45
	.dw __str_46
	.dw __str_47
	.dw __str_48
	.dw __str_49
	.dw __str_50
	.dw __str_51
	.dw __str_52
	.dw __str_53
	.dw __str_54
	.dw __str_55
	.dw __str_56
	.dw __str_57
	.dw __str_58
	.dw __str_59
	.dw __str_60
	.dw __str_61
	.dw __str_62
	.dw __str_63
	.dw __str_64
	.dw __str_65
	.dw __str_66
	.dw __str_67
	.dw __str_68
	.dw __str_69
	.dw __str_70
	.dw __str_71
	.dw __str_72
	.dw __str_73
	.dw __str_74
	.dw __str_75
	.dw __str_76
	.dw __str_77
	.dw __str_78
	.dw __str_79
	.dw __str_80
	.dw __str_81
	.dw __str_82
	.dw __str_83
	.dw __str_84
	.dw __str_85
	.dw __str_86
	.dw __str_87
	.dw __str_88
	.dw __str_89
	.dw __str_90
	.dw __str_91
	.dw __str_92
	.dw __str_93
	.dw __str_94
	.dw __str_95
	.dw __str_96
	.dw __str_97
	.dw __str_98
	.dw __str_99
	.dw __str_100
	.dw __str_101
	.dw __str_102
	.dw __str_103
	.dw __str_104
	.dw __str_105
	.dw __str_106
	.dw __str_107
	.dw __str_108
	.dw __str_109
	.dw __str_110
	.dw __str_111
	.dw __str_112
	.dw __str_113
	.dw __str_114
	.dw __str_115
	.dw __str_116
	.dw __str_117
	.dw __str_118
	.dw __str_119
	.dw __str_120
	.dw __str_121
	.dw __str_122
	.dw __str_123
	.dw __str_124
_tok_len:
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x01	; 1
	.db #0x02	; 2
	.db #0x02	; 2
	.db #0x02	; 2
	.db #0x02	; 2
	.db #0x02	; 2
	.db #0x02	; 2
	.db #0x02	; 2
	.db #0x02	; 2
	.db #0x03	; 3
	.db #0x02	; 2
	.db #0x03	; 3
	.db #0x04	; 4
	.db #0x02	; 2
	.db #0x03	; 3
	.db #0x02	; 2
	.db #0x02	; 2
	.db #0x05	; 5
	.db #0x04	; 4
	.db #0x02	; 2
	.db #0x02	; 2
	.db #0x02	; 2
	.db #0x02	; 2
	.db #0x02	; 2
	.db #0x02	; 2
	.db #0x09	; 9
	.db #0x09	; 9
	.db #0x02	; 2
	.db #0x03	; 3
	.db #0x02	; 2
	.db #0x02	; 2
	.db #0x02	; 2
	.db #0x02	; 2
	.db #0x02	; 2
	.db #0x04	; 4
	.db #0x02	; 2
	.db #0x04	; 4
	.db #0x02	; 2
	.db #0x02	; 2
	.db #0x02	; 2
	.db #0x02	; 2
	.db #0x06	; 6
	.db #0x02	; 2
	.db #0x02	; 2
	.db #0x02	; 2
	.db #0x03	; 3
	.db #0x02	; 2
	.db #0x05	; 5
	.db #0x03	; 3
	.db #0x05	; 5
	.db #0x05	; 5
	.db #0x07	; 7
	.db #0x03	; 3
	.db #0x03	; 3
	.db #0x02	; 2
	.db #0x02	; 2
	.db #0x02	; 2
	.db #0x0c	; 12
	.db #0x0b	; 11
	.db #0x06	; 6
	.db #0x02	; 2
	.db #0x02	; 2
	.db #0x02	; 2
	.db #0x02	; 2
	.db #0x03	; 3
	.db #0x04	; 4
	.db #0x02	; 2
	.db #0x04	; 4
	.db #0x02	; 2
	.db #0x02	; 2
	.db #0x03	; 3
	.db #0x02	; 2
	.db #0x02	; 2
	.db #0x02	; 2
	.db #0x02	; 2
__str_0:
	.db 0x00
__str_1:
	.ascii " "
	.db 0x00
__str_2:
	.ascii "a"
	.db 0x00
__str_3:
	.ascii "b"
	.db 0x00
__str_4:
	.ascii "c"
	.db 0x00
__str_5:
	.ascii "d"
	.db 0x00
__str_6:
	.ascii "e"
	.db 0x00
__str_7:
	.ascii "f"
	.db 0x00
__str_8:
	.ascii "g"
	.db 0x00
__str_9:
	.ascii "h"
	.db 0x00
__str_10:
	.ascii "i"
	.db 0x00
__str_11:
	.ascii "j"
	.db 0x00
__str_12:
	.ascii "k"
	.db 0x00
__str_13:
	.ascii "l"
	.db 0x00
__str_14:
	.ascii "m"
	.db 0x00
__str_15:
	.ascii "n"
	.db 0x00
__str_16:
	.ascii "o"
	.db 0x00
__str_17:
	.ascii "p"
	.db 0x00
__str_18:
	.ascii "q"
	.db 0x00
__str_19:
	.ascii "r"
	.db 0x00
__str_20:
	.ascii "s"
	.db 0x00
__str_21:
	.ascii "t"
	.db 0x00
__str_22:
	.ascii "u"
	.db 0x00
__str_23:
	.ascii "v"
	.db 0x00
__str_24:
	.ascii "w"
	.db 0x00
__str_25:
	.ascii "x"
	.db 0x00
__str_26:
	.ascii "y"
	.db 0x00
__str_27:
	.ascii "z"
	.db 0x00
__str_28:
	.ascii "0"
	.db 0x00
__str_29:
	.ascii "1"
	.db 0x00
__str_30:
	.ascii "2"
	.db 0x00
__str_31:
	.ascii "3"
	.db 0x00
__str_32:
	.ascii "4"
	.db 0x00
__str_33:
	.ascii "5"
	.db 0x00
__str_34:
	.ascii "6"
	.db 0x00
__str_35:
	.ascii "7"
	.db 0x00
__str_36:
	.ascii "8"
	.db 0x00
__str_37:
	.ascii "9"
	.db 0x00
__str_38:
	.ascii "."
	.db 0x00
__str_39:
	.ascii ","
	.db 0x00
__str_40:
	.ascii "?"
	.db 0x00
__str_41:
	.ascii "!"
	.db 0x00
__str_42:
	.ascii "'"
	.db 0x00
__str_43:
	.ascii "-"
	.db 0x00
__str_44:
	.ascii ":"
	.db 0x00
__str_45:
	.ascii "("
	.db 0x00
__str_46:
	.ascii ")"
	.db 0x00
__str_47:
	.ascii "/"
	.db 0x00
__str_48:
	.ascii "&"
	.db 0x00
__str_49:
	.db 0x22
	.db 0x00
__str_50:
	.ascii ";"
	.db 0x00
__str_51:
	.ascii " t"
	.db 0x00
__str_52:
	.ascii "th"
	.db 0x00
__str_53:
	.ascii "bo"
	.db 0x00
__str_54:
	.ascii "he"
	.db 0x00
__str_55:
	.ascii "me"
	.db 0x00
__str_56:
	.ascii " b"
	.db 0x00
__str_57:
	.ascii " a"
	.db 0x00
__str_58:
	.ascii "am"
	.db 0x00
__str_59:
	.ascii "ame"
	.db 0x00
__str_60:
	.ascii " g"
	.db 0x00
__str_61:
	.ascii "gam"
	.db 0x00
__str_62:
	.ascii " the"
	.db 0x00
__str_63:
	.ascii " i"
	.db 0x00
__str_64:
	.ascii " bo"
	.db 0x00
__str_65:
	.ascii "oy"
	.db 0x00
__str_66:
	.ascii "on"
	.db 0x00
__str_67:
	.ascii " game"
	.db 0x00
__str_68:
	.ascii " boy"
	.db 0x00
__str_69:
	.ascii "or"
	.db 0x00
__str_70:
	.ascii " c"
	.db 0x00
__str_71:
	.ascii "at"
	.db 0x00
__str_72:
	.ascii "ow"
	.db 0x00
__str_73:
	.ascii " s"
	.db 0x00
__str_74:
	.ascii "re"
	.db 0x00
__str_75:
	.ascii " game boy"
	.db 0x00
__str_76:
	.ascii " the game"
	.db 0x00
__str_77:
	.ascii "ut"
	.db 0x00
__str_78:
	.ascii " on"
	.db 0x00
__str_79:
	.ascii "nd"
	.db 0x00
__str_80:
	.ascii "er"
	.db 0x00
__str_81:
	.ascii "an"
	.db 0x00
__str_82:
	.ascii " w"
	.db 0x00
__str_83:
	.ascii "in"
	.db 0x00
__str_84:
	.ascii "bout"
	.db 0x00
__str_85:
	.ascii " k"
	.db 0x00
__str_86:
	.ascii " abo"
	.db 0x00
__str_87:
	.ascii "ly"
	.db 0x00
__str_88:
	.ascii " d"
	.db 0x00
__str_89:
	.ascii "wh"
	.db 0x00
__str_90:
	.ascii "es"
	.db 0x00
__str_91:
	.ascii " about"
	.db 0x00
__str_92:
	.ascii "ry"
	.db 0x00
__str_93:
	.ascii " m"
	.db 0x00
__str_94:
	.ascii " p"
	.db 0x00
__str_95:
	.ascii "sor"
	.db 0x00
__str_96:
	.ascii "y,"
	.db 0x00
__str_97:
	.ascii " only"
	.db 0x00
__str_98:
	.ascii " kn"
	.db 0x00
__str_99:
	.ascii " know"
	.db 0x00
__str_100:
	.ascii "sorry"
	.db 0x00
__str_101:
	.ascii " i only"
	.db 0x00
__str_102:
	.ascii " in"
	.db 0x00
__str_103:
	.ascii "ry,"
	.db 0x00
__str_104:
	.ascii " l"
	.db 0x00
__str_105:
	.ascii " 1"
	.db 0x00
__str_106:
	.ascii "as"
	.db 0x00
__str_107:
	.ascii " i only know"
	.db 0x00
__str_108:
	.ascii " know about"
	.db 0x00
__str_109:
	.ascii "sorry,"
	.db 0x00
__str_110:
	.ascii "ri"
	.db 0x00
__str_111:
	.ascii "ar"
	.db 0x00
__str_112:
	.ascii "ed"
	.db 0x00
__str_113:
	.ascii "ol"
	.db 0x00
__str_114:
	.ascii " is"
	.db 0x00
__str_115:
	.ascii "what"
	.db 0x00
__str_116:
	.ascii "en"
	.db 0x00
__str_117:
	.ascii " and"
	.db 0x00
__str_118:
	.ascii " f"
	.db 0x00
__str_119:
	.ascii "le"
	.db 0x00
__str_120:
	.ascii " 19"
	.db 0x00
__str_121:
	.ascii " o"
	.db 0x00
__str_122:
	.ascii "te"
	.db 0x00
__str_123:
	.ascii "ou"
	.db 0x00
__str_124:
	.ascii " n"
	.db 0x00
	.area _INITIALIZER
	.area _CABS (ABS)
