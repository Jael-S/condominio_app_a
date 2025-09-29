#!/usr/bin/env python3
"""
Script para probar la funcionalidad de reservas de áreas comunes
"""

import requests
import json
from datetime import datetime, timedelta

# Configuración
BASE_URL = "http://localhost:8000"
API_BASE = f"{BASE_URL}/api"

def test_reservas():
    print("🧪 Iniciando pruebas de funcionalidad de reservas...")
    
    # 1. Crear un usuario de prueba (residente)
    print("\n1. Creando usuario de prueba...")
    usuario_data = {
        "username": "residente_test",
        "email": "residente@test.com",
        "password": "test123",
        "first_name": "Residente",
        "last_name": "Test",
        "rol": "residente"
    }
    
    try:
        # Crear usuario
        response = requests.post(f"{API_BASE}/usuarios/usuarios/", json=usuario_data)
        if response.status_code == 201:
            print("✅ Usuario creado exitosamente")
            user_data = response.json()
            user_id = user_data['id']
        else:
            print(f"⚠️ Usuario ya existe o error: {response.status_code}")
            # Intentar obtener el usuario existente
            response = requests.get(f"{API_BASE}/usuarios/usuarios/")
            users = response.json()
            user_id = None
            for user in users:
                if user['username'] == 'residente_test':
                    user_id = user['id']
                    break
            if not user_id:
                print("❌ No se pudo crear o encontrar usuario")
                return
    except Exception as e:
        print(f"❌ Error creando usuario: {e}")
        return
    
    # 2. Hacer login
    print("\n2. Haciendo login...")
    login_data = {
        "username": "residente_test",
        "password": "test123"
    }
    
    try:
        response = requests.post(f"{API_BASE}/auth/login/", json=login_data)
        if response.status_code == 200:
            auth_data = response.json()
            token = auth_data['token']
            print("✅ Login exitoso")
        else:
            print(f"❌ Error en login: {response.status_code} - {response.text}")
            return
    except Exception as e:
        print(f"❌ Error en login: {e}")
        return
    
    # Headers para las siguientes peticiones
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    # 3. Crear áreas comunes de prueba
    print("\n3. Creando áreas comunes de prueba...")
    areas_data = [
        {
            "nombre": "Gimnasio",
            "tipo": "Gimnasio",
            "descripcion": "Gimnasio equipado con máquinas de ejercicio",
            "estado": True
        },
        {
            "nombre": "Salón de Eventos",
            "tipo": "Salón de eventos",
            "descripcion": "Salón para eventos y celebraciones",
            "estado": True
        },
        {
            "nombre": "Piscina",
            "tipo": "Piscina",
            "descripcion": "Piscina comunitaria",
            "estado": True
        }
    ]
    
    areas_creadas = []
    for area_data in areas_data:
        try:
            response = requests.post(f"{API_BASE}/mantenimiento/areas-comunes/", 
                                   json=area_data, headers=headers)
            if response.status_code == 201:
                area = response.json()
                areas_creadas.append(area)
                print(f"✅ Área creada: {area['nombre']}")
            else:
                print(f"⚠️ Error creando área {area_data['nombre']}: {response.status_code}")
        except Exception as e:
            print(f"❌ Error creando área {area_data['nombre']}: {e}")
    
    if not areas_creadas:
        print("❌ No se pudieron crear áreas comunes")
        return
    
    # 4. Obtener áreas disponibles
    print("\n4. Obteniendo áreas disponibles...")
    try:
        response = requests.get(f"{API_BASE}/mantenimiento/areas-comunes/", headers=headers)
        if response.status_code == 200:
            areas = response.json()
            print(f"✅ Se encontraron {len(areas)} áreas comunes")
            for area in areas:
                print(f"   - {area['nombre']} ({area['tipo']})")
        else:
            print(f"❌ Error obteniendo áreas: {response.status_code}")
    except Exception as e:
        print(f"❌ Error obteniendo áreas: {e}")
    
    # 5. Consultar disponibilidad
    print("\n5. Consultando disponibilidad...")
    if areas_creadas:
        area_id = areas_creadas[0]['id']
        fecha = (datetime.now() + timedelta(days=1)).strftime('%Y-%m-%d')
        
        try:
            response = requests.get(
                f"{API_BASE}/mantenimiento/reservas/horarios_disponibles/",
                params={
                    'area_id': area_id,
                    'fecha': fecha
                },
                headers=headers
            )
            if response.status_code == 200:
                data = response.json()
                horarios = data['horarios_disponibles']
                print(f"✅ Horarios disponibles para {fecha}: {len(horarios)}")
                for horario in horarios[:5]:  # Mostrar solo los primeros 5
                    print(f"   - {horario['hora_inicio']} - {horario['hora_fin']}")
            else:
                print(f"❌ Error consultando disponibilidad: {response.status_code}")
        except Exception as e:
            print(f"❌ Error consultando disponibilidad: {e}")
    
    # 6. Crear una reserva
    print("\n6. Creando reserva de prueba...")
    if areas_creadas:
        reserva_data = {
            "area": areas_creadas[0]['id'],
            "fecha": (datetime.now() + timedelta(days=1)).strftime('%Y-%m-%d'),
            "hora_inicio": "10:00",
            "hora_fin": "11:00",
            "motivo": "Prueba de funcionalidad",
            "costo": 0.0
        }
        
        try:
            response = requests.post(f"{API_BASE}/mantenimiento/reservas/", 
                                   json=reserva_data, headers=headers)
            if response.status_code == 201:
                reserva = response.json()
                print(f"✅ Reserva creada exitosamente: ID {reserva['id']}")
                print(f"   - Área: {reserva.get('area_nombre', 'N/A')}")
                print(f"   - Fecha: {reserva['fecha']}")
                print(f"   - Horario: {reserva['hora_inicio']} - {reserva['hora_fin']}")
                print(f"   - Estado: {reserva['estado']}")
            else:
                print(f"❌ Error creando reserva: {response.status_code} - {response.text}")
        except Exception as e:
            print(f"❌ Error creando reserva: {e}")
    
    # 7. Obtener reservas del usuario
    print("\n7. Obteniendo reservas del usuario...")
    try:
        response = requests.get(f"{API_BASE}/mantenimiento/reservas/", headers=headers)
        if response.status_code == 200:
            reservas = response.json()
            print(f"✅ Se encontraron {len(reservas)} reservas")
            for reserva in reservas:
                print(f"   - {reserva.get('area_nombre', 'N/A')} - {reserva['fecha']} - {reserva['hora_inicio']}")
        else:
            print(f"❌ Error obteniendo reservas: {response.status_code}")
    except Exception as e:
        print(f"❌ Error obteniendo reservas: {e}")
    
    print("\n🎉 Pruebas completadas!")

if __name__ == "__main__":
    test_reservas()


