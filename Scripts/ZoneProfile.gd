class_name ZoneProfile
extends Resource

## โปรไฟล์บรรยากาศของโซนหนึ่งในหอคอย LUMEN
##
## ทุกอย่างที่เปลี่ยน "ความรู้สึกของความสูง" อยู่ในไฟล์เดียวนี้
## อาร์ตติสต์แก้ .tres ได้เลยโดยไม่ต้องแตะโค้ด
## ดูค่าอ้างอิงทั้งหมดได้ใน docs/LUMEN_GDD (Ascent Bible) หัวข้อ 02 และ 03

@export_group("ข้อมูลโซน")
@export var zone_name: String = ""
@export var zone_name_en: String = ""
## เลเวล (หน้าจอ) แรกของโซนนี้ นับจาก 1 ที่พื้นดิน — ต้องเรียงจากน้อยไปมากใน LumenLighting.zones
@export var first_level: int = 1

@export_group("การไล่สีภาพรวม")
## สีของ CanvasModulate — คูณทับทั้งฉาก ใช้ย้อมโทน ไม่ใช่ใช้กดให้มืดสนิท
## อาร์ตของเกมนี้ระบายแสงเงามาแล้ว ค่าต่ำกว่า 0.6 จะทำให้อ่านแท่นไม่ออก
@export var ambient: Color = Color(1, 1, 1, 1)
@export_range(0.0, 2.0, 0.01) var saturation: float = 1.0
@export_range(0.0, 2.0, 0.01) var contrast: float = 1.0

@export_group("แสงฟุ้ง")
@export_range(0.0, 2.0, 0.01) var glow_intensity: float = 0.5
@export_range(0.0, 1.0, 0.01) var glow_bloom: float = 0.1
## ต่ำกว่า 1.0 = ให้ไฮไลต์ในอาร์ต SDR ฟุ้งด้วย · 1.0 ขึ้นไป = ฟุ้งเฉพาะไฟที่เกิน HDR
@export_range(0.0, 2.0, 0.01) var glow_hdr_threshold: float = 0.95

@export_group("ไฟถ่านของผู้เล่น")
@export var ember_color: Color = Color(1, 0.718, 0.396, 1)
## ยิ่งสูงยิ่งต่ำ — ถ่านในมือกำลังจะหมด (GDD 01: Core Twist)
@export_range(0.0, 3.0, 0.01) var ember_energy: float = 1.2
@export_range(0.5, 8.0, 0.05) var ember_scale: float = 3.0
