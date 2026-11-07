import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/template_config_model.dart';

class TemplateConfigNotifier extends Notifier<TemplateConfigModel> {
  @override
  TemplateConfigModel build() => const TemplateConfigModel();

  void updateConfig(TemplateConfigModel newConfig) => state = newConfig;

  void setTemplateId(String templateId) {
    state = state.copyWith(templateId: templateId);
  }

  void setTemplate(String id) => setTemplateId(id);

  void setPrimaryColor(int colorHex) {
    state = state.copyWith(primaryColorHex: colorHex);
  }

  void setColor(int hex) => setPrimaryColor(hex);

  void toggleOption({
    bool? showLogo,
    bool? showGstin,
    bool? showCustomerGstin,
    bool? showSupplyDetails,
    bool? showHsnSac,
    bool? showBankDetails,
    bool? showUpiQr,
    bool? showSignature,
    bool? showTerms,
    bool? showPaymentDueAlert,
  }) {
    state = state.copyWith(
      showLogo: showLogo,
      showGstin: showGstin,
      showCustomerGstin: showCustomerGstin,
      showSupplyDetails: showSupplyDetails,
      showHsnSac: showHsnSac,
      showBankDetails: showBankDetails,
      showUpiQr: showUpiQr,
      showSignature: showSignature,
      showTerms: showTerms,
      showPaymentDueAlert: showPaymentDueAlert,
    );
  }
}

final templateConfigProvider =
    NotifierProvider<TemplateConfigNotifier, TemplateConfigModel>(TemplateConfigNotifier.new);
