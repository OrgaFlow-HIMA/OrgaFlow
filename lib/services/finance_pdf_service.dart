import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/finance_transaction.dart';

class FinancePdfService {
  static String _formatRupiah(int number) {
    return 'Rp ${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  static String _formatTanggal(DateTime dt) {
    const bulan = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${bulan[dt.month - 1]} ${dt.year}';
  }

  /// Generate & tampilkan preview cetak / unduh / share PDF Laporan Keuangan
  static Future<void> generateAndPreviewReport({
    required List<FinanceTransaction> transactions,
    required String dicetakOleh,
    required String rolePencetak,
    required String periodeLabel,
  }) async {
    final pdf = pw.Document();

    int totalMasuk = 0;
    int totalKeluar = 0;
    for (final tx in transactions) {
      if (tx.isIncome) {
        totalMasuk += tx.nominal;
      } else {
        totalKeluar += tx.nominal;
      }
    }
    final saldoAkhir = totalMasuk - totalKeluar;
    final tanggalCetak = _formatTanggal(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // ===== KOP SURAT ORGANISASI =====
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 12),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.blue900, width: 2),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'HIMPUNAN MAHASISWA TEKNIK INFORMATIKA (HIMA TI)',
                    style: pw.TextStyle(
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Laporan Pertanggungjawaban Keuangan & Buku Kas Organisasi — OrgaFlow',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // ===== INFO PERIODE & PENCETAK =====
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Periode Laporan: $periodeLabel',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Dicetak oleh: $dicetakOleh ($rolePencetak)',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  'Tanggal Cetak: $tanggalCetak',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // ===== KARTU RINGKASAN SALDO =====
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.blue200),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildPdfSummaryItem(
                    'Total Pemasukan',
                    _formatRupiah(totalMasuk),
                    PdfColors.green800,
                  ),
                  _buildPdfSummaryItem(
                    'Total Pengeluaran',
                    _formatRupiah(totalKeluar),
                    PdfColors.red800,
                  ),
                  _buildPdfSummaryItem(
                    'Saldo Akhir Kas',
                    _formatRupiah(saldoAkhir),
                    PdfColors.blue900,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 18),

            // ===== JUDUL TABEL =====
            pw.Text(
              'Rincian Mutasi Transaksi Kas (${transactions.length} Transaksi)',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey900,
              ),
            ),
            pw.SizedBox(height: 8),

            // ===== TABEL TRANSAKSI =====
            if (transactions.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Text(
                  'Tidak ada data transaksi pada periode ini.',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue900,
                ),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 6,
                ),
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                columnWidths: {
                  0: const pw.FixedColumnWidth(24),
                  1: const pw.FixedColumnWidth(65),
                  2: const pw.FlexColumnWidth(3),
                  3: const pw.FixedColumnWidth(52),
                  4: const pw.FixedColumnWidth(75),
                  5: const pw.FixedColumnWidth(62),
                },
                headers: [
                  'No',
                  'Tanggal',
                  'Keterangan / Judul',
                  'Jenis',
                  'Nominal',
                  'Status Audit',
                ],
                data: List.generate(transactions.length, (index) {
                  final tx = transactions[index];
                  final ket = tx.deskripsi.isNotEmpty
                      ? '${tx.judul}\n(${tx.deskripsi})'
                      : tx.judul;
                  return [
                    '${index + 1}',
                    _formatTanggal(tx.createdAt),
                    ket,
                    tx.isIncome ? 'Masuk' : 'Keluar',
                    '${tx.isIncome ? '+' : '-'} ${_formatRupiah(tx.nominal)}',
                    tx.isDikonfirmasi ? 'Sah' : 'Pending',
                  ];
                }),
              ),

            pw.SizedBox(height: 32),

            // ===== KOLOM TANDA TANGAN PENGESAHAN =====
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSignatureBox('Dibuat oleh,', 'Bendahara Umum'),
                _buildSignatureBox('Diperiksa & Disahkan,', 'Ketua Himpunan'),
                _buildSignatureBox('Mengetahui,', 'Dekan / Dosen Pembina'),
              ],
            ),
          ];
        },
      ),
    );

    final fileName =
        'Laporan_Keuangan_HIMATI_${DateTime.now().millisecondsSinceEpoch}.pdf';

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: fileName,
    );
  }

  static pw.Widget _buildPdfSummaryItem(
    String label,
    String value,
    PdfColor color,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSignatureBox(String title, String roleName) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(title, style: const pw.TextStyle(fontSize: 9)),
        pw.Text(
          roleName,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 45),
        pw.Container(
          width: 110,
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey800)),
          ),
          padding: const pw.EdgeInsets.only(top: 3),
          alignment: pw.Alignment.center,
          child: pw.Text(
            '( .................................. )',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ),
      ],
    );
  }
}
