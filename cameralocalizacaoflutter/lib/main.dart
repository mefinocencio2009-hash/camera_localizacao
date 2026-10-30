import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const MainApp());

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Perfil com Foto e Localização',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F3FF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const TelaPerfil(),
    );
  }
}

class TelaPerfil extends StatefulWidget {
  const TelaPerfil({super.key});

  @override
  State<TelaPerfil> createState() => _TelaPerfilState();
}

class _TelaPerfilState extends State<TelaPerfil> {
  // ============ NOME ============
  final TextEditingController _nomeController = TextEditingController();
  String nome = '';

  // ============ FOTO ============
  File? foto;
  final ImagePicker _picker = ImagePicker();

  // ============ LOCALIZAÇÃO ============
  String localizacao = 'Localização ainda não obtida';
  bool localizacaoObtida = false;
  bool buscandoLocalizacao = false;
  DateTime? ultimaAtualizacao;

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  // ---------- FOTO ----------
  Future<void> escolherFoto(ImageSource origem) async {
    try {
      final imagem = await _picker.pickImage(source: origem);
      if (imagem == null) return;
      setState(() => foto = File(imagem.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao obter imagem: $e')),
      );
    }
  }

  void removerFoto() => setState(() => foto = null);

  // ---------- LOCALIZAÇÃO ----------
  Future<void> obterLocalizacao() async {
    setState(() => buscandoLocalizacao = true);

    try {
      final servicoAtivo = await Geolocator.isLocationServiceEnabled();
      if (!servicoAtivo) {
        atualizarErroLocalizacao('Ative o GPS do dispositivo.');
        return;
      }

      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }
      if (permissao == LocationPermission.denied) {
        atualizarErroLocalizacao('Permissão de localização negada.');
        return;
      }
      if (permissao == LocationPermission.deniedForever) {
        atualizarErroLocalizacao(
          'Permissão negada permanentemente. Libere-a nas configurações.',
        );
        return;
      }

      final posicao = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      setState(() {
        localizacao =
            'Latitude: ${posicao.latitude.toStringAsFixed(4)}\n'
            'Longitude: ${posicao.longitude.toStringAsFixed(4)}';
        localizacaoObtida = true;
        buscandoLocalizacao = false;
        ultimaAtualizacao = DateTime.now();
      });
    } catch (_) {
      atualizarErroLocalizacao('Não foi possível obter a localização.');
    }
  }

  void atualizarErroLocalizacao(String mensagem) {
    if (!mounted) return;
    setState(() {
      localizacao = mensagem;
      localizacaoObtida = false;
      buscandoLocalizacao = false;
    });
  }

  String _fmtData(DateTime d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year} '
        'às ${dois(d.hour)}:${dois(d.minute)}';
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iniciais = nome.trim().isEmpty
        ? null
        : nome
            .trim()
            .split(' ')
            .map((p) => p[0])
            .take(2)
            .join()
            .toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ===== AVATAR =====
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Colors.deepPurple, Colors.pinkAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage: foto != null ? FileImage(foto!) : null,
                    child: foto == null
                        ? (iniciais != null
                            ? Text(
                                iniciais,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.deepPurple,
                              ))
                        : null,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ===== NOME EXIBIDO =====
              if (nome.trim().isNotEmpty)
                Center(
                  child: Text(
                    nome.trim(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // ===== CAMPO DE NOME =====
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _nomeController,
                    onChanged: (v) => setState(() => nome = v),
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Seu nome',
                      hintText: 'Digite seu nome',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ===== BOTÕES DA FOTO =====
              ElevatedButton.icon(
                onPressed: () => escolherFoto(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Tirar foto'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => escolherFoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Escolher da galeria'),
              ),
              if (foto != null) ...[
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: removerFoto,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    'Remover foto',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // ===== CARD DA LOCALIZAÇÃO =====
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        localizacaoObtida
                            ? Icons.location_on
                            : Icons.location_searching,
                        size: 40,
                        color: localizacaoObtida
                            ? Colors.green
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        localizacao,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                      if (ultimaAtualizacao != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Atualizada em ${_fmtData(ultimaAtualizacao!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ===== BOTÃO DE LOCALIZAÇÃO =====
              ElevatedButton.icon(
                onPressed: buscandoLocalizacao ? null : obterLocalizacao,
                icon: buscandoLocalizacao
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  buscandoLocalizacao
                      ? 'Obtendo localização...'
                      : 'Usar minha localização',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}