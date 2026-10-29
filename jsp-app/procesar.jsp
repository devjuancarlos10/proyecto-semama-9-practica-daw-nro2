<%@ page import="java.util.*" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
  Guía Práctica Grupal Semana 09 - Desarrollo de Aplicaciones Web
  Archivo: jsp-app/procesar.jsp (Refactorizado con Validación de Correos Únicos)
  
  /* IA: Validación de unicidad de correos en HttpSession de Tomcat
     → Solución manual: Se itera sobre List<Map<String, String>> comparando con equalsIgnoreCase() 
       para evitar duplicidad de contactos registrados en la memoria Heap de la JVM. */
--%>
<%
    String metodo = request.getMethod();
    String accion = request.getParameter("accion");
    String ver = request.getParameter("ver");

    // Limpieza de sesión
    if ("limpiar".equals(accion)) {
        session.removeAttribute("registros");
        response.sendRedirect("index.jsp");
        return;
    }

    String tipoAlerta = null;
    String textoAlerta = null;

    if ("POST".equalsIgnoreCase(metodo)) {
        request.setCharacterEncoding("UTF-8");
        String nombre = request.getParameter("nombre");
        String correo = request.getParameter("correo");

        if (nombre == null || nombre.trim().length() < 2 || correo == null || !correo.matches("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}$")) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.println("<h3 style='color:red;'>Datos inválidos: Verifique los campos enviados.</h3><a href='index.jsp'>Volver</a>");
            return;
        }

        // Sanitización XSS
        String nombreSan = nombre.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
        String correoSan = correo.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");

        // Obtener o inicializar lista en HttpSession
        @SuppressWarnings("unchecked")
        List<Map<String, String>> registros = (List<Map<String, String>>) session.getAttribute("registros");
        if (registros == null) {
            registros = new ArrayList<>();
        }

        // VALIDACIÓN DE NO DUPLICADOS: Verificar si el correo ya existe
        boolean correoDuplicado = false;
        for (Map<String, String> reg : registros) {
            if (correoSan.equalsIgnoreCase(reg.get("correo"))) {
                correoDuplicado = true;
                break;
            }
        }

        if (correoDuplicado) {
            tipoAlerta = "warning";
            textoAlerta = "⚠️ El correo <strong>" + correoSan + "</strong> ya se encuentra registrado. No se permiten registros duplicados.";
        } else {
            Map<String, String> nuevo = new LinkedHashMap<>();
            nuevo.put("nombre", nombreSan);
            nuevo.put("correo", correoSan);
            nuevo.put("fecha", new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm:ss").format(new Date()));

            registros.add(nuevo);
            session.setAttribute("registros", registros);
            tipoAlerta = "success";
            textoAlerta = "✓ Contacto <strong>" + nombreSan + "</strong> (" + correoSan + ") registrado exitosamente en la memoria JVM de Tomcat.";
        }
    } else if ("GET".equalsIgnoreCase(metodo) && "tabla".equals(ver)) {
        // Permitido para consultar la lista acumulada
    } else {
        // Restricción técnica: 405 Method Not Allowed
        response.setStatus(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
        response.setHeader("Allow", "POST, GET");
        out.println("<h2 style='font-family:sans-serif; color:#dc2626;'>405 - Método no permitido</h2>");
        out.println("<p style='font-family:sans-serif;'>Este formulario solo acepta envíos mediante método POST.</p>");
        out.println("<a href='index.jsp'>Volver al formulario</a>");
        return;
    }

    @SuppressWarnings("unchecked")
    List<Map<String, String>> listaRegistros = (List<Map<String, String>>) session.getAttribute("registros");
    int totalRegistros = (listaRegistros != null) ? listaRegistros.size() : 0;
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Lab 09 | Registros Almacenados (JSP)</title>
    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
        }

        body {
            background-color: #f8fafc;
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
            background: #ffedd5;
            color: #c2410c;
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
            background: #fff7ed;
            color: #9a3412;
            font-weight: 600;
            padding: 12px 14px;
            border-bottom: 2px solid #fed7aa;
        }

        td {
            padding: 12px 14px;
            border-bottom: 1px solid #f1f5f9;
            color: #1e293b;
        }

        tr:hover td {
            background: #fafaf9;
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
            background: #ea580c;
            color: #ffffff;
            border: none;
        }

        .btn-primary:hover {
            background: #c2410c;
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
            <h2>Registros Almacenados en HttpSession (JSP)</h2>
            <span class="count-badge"><%= totalRegistros %> <%= totalRegistros == 1 ? "contacto" : "contactos" %></span>
        </div>

        <% if (tipoAlerta != null) { %>
            <div class="alert <%= "warning".equals(tipoAlerta) ? "alert-warning" : "alert-success" %>">
                <span><%= textoAlerta %></span>
            </div>
        <% } %>

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
                    <% if (listaRegistros != null && !listaRegistros.isEmpty()) { %>
                        <% int idx = 1; for (Map<String, String> reg : listaRegistros) { %>
                            <tr>
                                <td style="color: #64748b; font-weight: 600;"><%= idx++ %></td>
                                <td><%= reg.get("nombre") %></td>
                                <td style="color: #ea580c;"><%= reg.get("correo") %></td>
                                <td style="color: #64748b; font-size: 13px;"><%= reg.get("fecha") %></td>
                            </tr>
                        <% } %>
                    <% } else { %>
                        <tr>
                            <td colspan="4" class="empty-state">No hay registros almacenados en la sesión actual.</td>
                        </tr>
                    <% } %>
                </tbody>
            </table>
        </div>

        <div class="btn-group">
            <a href="index.jsp" class="btn btn-primary">+ Registrar Otro Contacto (JSP)</a>
            <% if (totalRegistros > 0) { %>
                <a href="procesar.jsp?accion=limpiar" class="btn btn-danger" onclick="return confirm('¿Desea limpiar los registros de la sesión?')">Limpiar Sesión</a>
            <% } %>
        </div>
    </div>

</body>
</html>
