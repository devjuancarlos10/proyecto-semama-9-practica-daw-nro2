<?php
/**
 * Guía Práctica Grupal Semana 09 - Desarrollo de Aplicaciones Web
 * Archivo: php-app/procesar.php (Refactorizado con Validación de Correos Únicos)
 * 
 * IA: Validación de unicidad de correos y sanitización de inputs
 *  -> Solución manual: Se itera sobre $_SESSION['registros'] con strcasecmp() 
 *     para impedir duplicados en la sesión antes de insertar un nuevo elemento,
 *     manteniendo la integridad de los datos registrados.
 */

session_start();

$mensajeAlerta = null;

// Permitir visualización o limpieza de tabla si se solicita explícitamente vía GET
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    if (isset($_GET['accion']) && $_GET['accion'] === 'limpiar') {
        $_SESSION['registros'] = [];
        header('Location: index.html');
        exit;
    }
    
    // Si no es para ver la tabla acumulada, rechazar con 405 Method Not Allowed
    if (!isset($_GET['ver']) || $_GET['ver'] !== 'tabla') {
        http_response_code(405);
        header('Allow: POST, GET');
        exit('Método no permitido: Este endpoint procesa formularios mediante POST.');
    }
} else if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // 1. Obtener y validar entradas usando filter_input
    $rawNombre = filter_input(INPUT_POST, 'nombre', FILTER_DEFAULT);
    $rawCorreo = filter_input(INPUT_POST, 'correo', FILTER_VALIDATE_EMAIL);

    if (!$rawNombre || strlen(trim($rawNombre)) < 2 || !$rawCorreo) {
        http_response_code(400);
        exit('Datos inválidos: Verifique que el nombre y el correo electrónico sean correctos.');
    }

    // 2. Sanitización contra XSS con htmlspecialchars
    $nombre = htmlspecialchars(trim($rawNombre), ENT_QUOTES, 'UTF-8');
    $correo = htmlspecialchars(trim($rawCorreo), ENT_QUOTES, 'UTF-8');
    $fecha = date('d/m/Y H:i:s');

    // 3. Inicializar array de registros en sesión si no existe
    if (!isset($_SESSION['registros']) || !is_array($_SESSION['registros'])) {
        $_SESSION['registros'] = [];
    }

    // 4. VALIDACIÓN DE NO DUPLICADOS: Verificar si el correo ya existe
    $correoDuplicado = false;
    foreach ($_SESSION['registros'] as $reg) {
        if (strcasecmp($reg['correo'], $correo) === 0) {
            $correoDuplicado = true;
            break;
        }
    }

    if ($correoDuplicado) {
        $mensajeAlerta = [
            'tipo' => 'warning',
            'texto' => "⚠️ El correo <strong>{$correo}</strong> ya se encuentra registrado. No se permiten registros duplicados."
        ];
    } else {
        // Guardar registro acumulativo en $_SESSION
        $_SESSION['registros'][] = [
            'nombre' => $nombre,
            'correo' => $correo,
            'fecha'  => $fecha
        ];

        $mensajeAlerta = [
            'tipo' => 'success',
            'texto' => "✓ Contacto <strong>{$nombre}</strong> ({$correo}) registrado exitosamente en la sesión PHP."
        ];
    }
} else {
    http_response_code(405);
    exit('Método no permitido');
}

$total = isset($_SESSION['registros']) ? count($_SESSION['registros']) : 0;
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Lab 09 | Registros Almacenados (PHP)</title>
    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
        }

        body {
            background-color: #f1f5f9;
            color: #1e293b;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            padding: 24px;
        }

        .card {
            background: #ffffff;
            border-radius: 12px;
            box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.08);
            max-width: 680px;
            width: 100%;
            padding: 32px;
            border: 1px solid #e2e8f0;
        }

        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            flex-wrap: wrap;
            gap: 10px;
        }

        h2 {
            font-size: 20px;
            font-weight: 700;
            color: #0f172a;
        }

        .count-badge {
            background: #e0e7ff;
            color: #3730a3;
            padding: 4px 12px;
            border-radius: 9999px;
            font-size: 13px;
            font-weight: 600;
        }

        .alert {
            padding: 12px 16px;
            border-radius: 8px;
            font-size: 14px;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .alert-success {
            background: #ecfdf5;
            color: #065f46;
            border: 1px solid #a7f3d0;
        }

        .alert-warning {
            background: #fffbeb;
            color: #92400e;
            border: 1px solid #fde68a;
        }

        .table-responsive {
            overflow-x: auto;
            margin-bottom: 24px;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 14px;
            text-align: left;
        }

        th {
            background: #f8fafc;
            color: #475569;
            font-weight: 600;
            padding: 12px 14px;
            border-bottom: 2px solid #e2e8f0;
        }

        td {
            padding: 12px 14px;
            border-bottom: 1px solid #f1f5f9;
            color: #1e293b;
        }

        tr:hover td {
            background: #f8fafc;
        }

        .empty-state {
            text-align: center;
            padding: 30px;
            color: #94a3b8;
            font-style: italic;
        }

        .btn-group {
            display: flex;
            gap: 12px;
            flex-wrap: wrap;
        }

        .btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 10px 18px;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 600;
            text-decoration: none;
            cursor: pointer;
            transition: all 0.2s;
        }

        .btn-primary {
            background: #4f46e5;
            color: #ffffff;
            border: none;
        }

        .btn-primary:hover {
            background: #4338ca;
        }

        .btn-danger {
            background: #fee2e2;
            color: #991b1b;
            border: 1px solid #fecaca;
        }

        .btn-danger:hover {
            background: #fecaca;
        }
    </style>
</head>
<body>

    <div class="card">
        <div class="header">
            <h2>Registros Almacenados en $_SESSION</h2>
            <span class="count-badge"><?= $total ?> <?= $total === 1 ? 'contacto' : 'contactos' ?></span>
        </div>

        <?php if ($mensajeAlerta): ?>
            <div class="alert <?= $mensajeAlerta['tipo'] === 'warning' ? 'alert-warning' : 'alert-success' ?>">
                <span><?= $mensajeAlerta['texto'] ?></span>
            </div>
        <?php endif; ?>

        <div class="table-responsive">
            <table>
                <thead>
                    <tr>
                        <th style="width: 50px;">#</th>
                        <th>Nombre</th>
                        <th>Correo Electrónico</th>
                        <th style="width: 140px;">Fecha y Hora</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (!empty($_SESSION['registros'])): ?>
                        <?php foreach ($_SESSION['registros'] as $idx => $reg): ?>
                            <tr>
                                <td style="color: #64748b; font-weight: 600;"><?= $idx + 1 ?></td>
                                <td><?= $reg['nombre'] ?></td>
                                <td style="color: #4f46e5;"><?= $reg['correo'] ?></td>
                                <td style="color: #64748b; font-size: 13px;"><?= $reg['fecha'] ?? '-' ?></td>
                            </tr>
                        <?php endforeach; ?>
                    <?php else: ?>
                        <tr>
                            <td colspan="4" class="empty-state">No hay registros almacenados en la sesión actual.</td>
                        </tr>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>

        <div class="btn-group">
            <a href="index.html" class="btn btn-primary">+ Registrar Otro Contacto</a>
            <?php if ($total > 0): ?>
                <a href="procesar.php?accion=limpiar" class="btn btn-danger" onclick="return confirm('¿Desea limpiar los registros de la sesión?')">Limpiar Sesión</a>
            <?php endif; ?>
        </div>
    </div>

</body>
</html>
