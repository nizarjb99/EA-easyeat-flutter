import 'package:flutter/material.dart';

class LegalNoticePage extends StatelessWidget {
  const LegalNoticePage({super.key});

  static const Color orange = Color(0xFFFF7A1A);
  static const Color dark = Color(0xFF0F172A);
  static const Color grey = Color(0xFF64748B);
  static const Color bgLight = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900;

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: dark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Aviso Legal',
          style: TextStyle(color: dark, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            padding: EdgeInsets.symmetric(
              vertical: isMobile ? 40 : 80,
              horizontal: isMobile ? 20 : 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 40),
                _buildCard(
                  children: [
                    _buildSection(
                      '1. Titularidad del sitio web',
                      'La aplicación Easy Eat y el sitio web asociado son titularidad de [Nombre de la empresa], con domicilio social en [Dirección fiscal] y NIF/CIF [CIF/NIF].',
                    ),
                    _buildSection(
                      '2. Datos identificativos del responsable',
                      'En cumplimiento de la Ley 34/2002, de 11 de julio, de servicios de la sociedad de la información y de comercio electrónico, se informan los siguientes datos:\n\n'
                          '• Nombre comercial: Easy Eat\n'
                          '• Denominación social: [Nombre de la empresa]\n'
                          '• NIF: [CIF/NIF]\n'
                          '• Domicilio: [Dirección fiscal]\n'
                          '• Email: email@empresa.com',
                    ),
                    _buildSection(
                      '3. Objeto de la aplicación',
                      'Easy Eat es una plataforma SaaS diseñada para conectar a restaurantes con sus clientes, facilitando la gestión de reservas, programas de fidelización y la visualización de menús digitales.',
                    ),
                    _buildSection(
                      '4. Condiciones de uso',
                      'El acceso y uso de Easy Eat atribuye la condición de usuario e implica la aceptación plena de estas condiciones. El usuario se compromete a hacer un uso adecuado de los contenidos y servicios de la aplicación.',
                    ),
                    _buildSection(
                      '5. Propiedad intelectual e industrial',
                      'Todos los derechos de propiedad intelectual del contenido de esta aplicación y su diseño gráfico son titularidad exclusiva de Easy Eat o de terceros que han autorizado su uso, quedando prohibida su reproducción, distribución o transformación sin autorización previa.',
                    ),
                    _buildSection(
                      '6. Responsabilidad del usuario',
                      'El usuario es responsable de la veracidad de los datos facilitados y del uso que realice de la plataforma. Easy Eat no se hace responsable de los daños derivados del uso incorrecto de la aplicación por parte de los usuarios.',
                    ),
                    _buildSection(
                      '7. Protección de datos personales',
                      'Easy Eat cumple con las directrices del Reglamento General de Protección de Datos (RGPD) y la Ley Orgánica de Protección de Datos y Garantía de Derechos Digitales (LOPDGDD). Los datos recogidos serán tratados con la finalidad de gestionar el servicio solicitado.',
                    ),
                    _buildSection(
                      '8. Uso de cookies',
                      'Easy Eat utiliza cookies técnicas y de análisis para mejorar la experiencia del usuario. Puede consultar el detalle en nuestra Política de Cookies.',
                    ),
                    _buildSection(
                      '9. Enlaces externos',
                      'En caso de que la aplicación contenga enlaces a otros sitios de Internet, Easy Eat no ejercerá ningún tipo de control sobre dichos sitios y contenidos.',
                    ),
                    _buildSection(
                      '10. Legislación aplicable y jurisdicción',
                      'Para la resolución de todas las controversias o cuestiones relacionadas con la presente aplicación, será de aplicación la legislación española, a la que se someten expresamente las partes.',
                    ),
                    _buildSection(
                      '11. Contacto',
                      'Para cualquier consulta sobre este aviso legal, puede contactar con nosotros a través de email@empresa.com.',
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'Última actualización: Mayo 2024',
                    style: TextStyle(color: grey.withOpacity(0.7), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'DOCUMENTACIÓN LEGAL',
            style: TextStyle(
              color: orange,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Aviso Legal y Condiciones de Uso',
          style: TextStyle(
            color: dark,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'En este documento encontrarás toda la información relativa a la titularidad de Easy Eat y las normas que regulan el uso de nuestra plataforma.',
          style: TextStyle(
            color: grey,
            fontSize: 18,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: dark,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              color: grey,
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
