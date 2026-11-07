# Invoicify — Technical Architecture, Codebase Knowledge Base & Development Guide

> **Document Version:** 1.1.0  
> **Last Updated:** November 2026  
> **Project Name:** Invoicify (`invoice_generator`)  
> **Domain:** Smart GST Invoicing, Billing & Financial SaaS for Indian Businesses  
> **Target Platforms:** Android, iOS, Web, macOS/Desktop  

> [!IMPORTANT]
> **MANDATORY AGENT DIRECTIVE:**  
> The AI assistant must **always read this file before performing any task** to ensure full architectural and domain compliance, and **must update this document immediately after every task** (recording changes in Section 12: Activity Log & Task Tracking) to maintain an accurate, living record of all changes, conventions, and evolving needs.

---

## 1. Executive Project Summary

**Invoicify** is a production-grade, cross-platform mobile and web application built with **Flutter**, designed specifically for Indian small-to-medium enterprises (SMEs), freelancers, agencies, contractors, and merchants.

The application simplifies and automates end-to-end billing:
1. **GST Compliance:** Automated Intra-State (CGST + SGST) vs. Inter-State (IGST) split, HSN/SAC code tracking, and GST tax slabs (0%, 5%, 12%, 18%, 28%).
2. **Non-GST / Bill of Supply Mode:** Full flexibility to generate non-GST invoices, proforma invoices, delivery challans, or estimates with custom headers, zero-tax calculations, and optional due dates/places of supply.
3. **Multi-Template PDF Generator:** Real-time generation of pixel-perfect printable A4 PDF invoices with custom brand primary colors, dynamic UPI QR codes for instant scan-and-pay, embedded logos, and authorized signatures.
4. **Cloud-First Architecture with Offline Caching:** Built on **Supabase** (PostgreSQL, Auth, Storage, and Row Level Security) combined with `FlutterSecureStorage` and `SharedPreferences` for local persistence and offline resilience.
5. **Strict Asset Storage Optimization:** Dedicated pure-Dart image compression guaranteeing all logos and signatures are strictly capped to $\le$ 200 KB and enforcing a single-file-per-user lifecycle to eliminate cloud storage bloat.

---

## 2. Technology Stack & Key Dependencies

| Layer | Technology | Version | Purpose |
| :--- | :--- | :--- | :--- |
| **Framework** | Flutter | SDK `^3.7.0` | Cross-platform UI toolkit (Android, iOS, Web) |
| **Language** | Dart | `>=3.7.0 <4.0.0` | Strongly typed object-oriented programming |
| **State Management** | `flutter_riverpod` | `^3.3.2` | Compile-safe, reactive state and dependency injection |
| **Routing** | `go_router` | `^17.0.0` | Declarative routing, auth guards, stateful shell branches |
| **Backend & BaaS** | `supabase_flutter` | `^2.8.3` | Authentication, PostgreSQL database, RLS, Storage |
| **HTTP Client** | `dio` + `pretty_dio_logger` | `^5.11.1` | REST client, interceptors, network logging |
| **Secure Storage** | `flutter_secure_storage` | `^10.3.2` | Encrypted keychain/keystore token storage |
| **Local Cache** | `shared_preferences` | `^2.5.3` | User profile, preferences, and offline fallback |
| **PDF Generation** | `pdf` + `printing` | `^3.11.3` / `^5.14.3` | Vector PDF document canvas, previewer, direct printing |
| **Image Compression** | `image` (pure Dart) | `^4.5.2` | In-memory scaling, JPEG/PNG re-encoding ($\le$ 200KB) |
| **Media Capture** | `image_picker` | `^1.1.2` | Gallery picking and camera capture |
| **Charts** | `fl_chart` | `0.70.2` | Visual revenue trends and performance analytics |
| **Typography & UI** | `google_fonts` | `^6.3.2` | Runtime font fetching (Roboto, Inter) |
| **Sharing** | `share_plus` + `url_launcher` | `^11.0.0` / `^6.3.2` | Native PDF sharing, UPI intent, WhatsApp trigger |

---

## 3. Architecture & Directory Blueprint

The project follows a **Feature-First Clean Architecture** with explicit separation into **Core**, **Features**, and **Navigation** layers.

```
lib/
├── main.dart                               # Application bootstrap & ProviderScope
├── core/                                   # Cross-cutting foundational modules
│   ├── config/                             # Supabase credentials & project configuration
│   │   └── supabase_config.dart
│   ├── constants/                          # Global colors, dimensions, typography, API routes
│   │   ├── api_endpoints.dart
│   │   ├── app_colors.dart
│   │   ├── app_dimensions.dart
│   │   └── app_strings.dart
│   ├── network/                            # Dio HTTP engine & interceptors
│   │   ├── api_client.dart
│   │   ├── api_exceptions.dart
│   │   └── auth_interceptor.dart
│   ├── services/                           # Pure services (Storage, Image compression)
│   │   ├── image_compressor_service.dart
│   │   └── supabase_storage_service.dart
│   ├── storage/                            # Secure & shared preference storage wrappers
│   │   └── secure_storage_service.dart
│   ├── theme/                              # Material 3 light/dark themes & typography
│   │   ├── app_theme.dart
│   │   └── typography.dart
│   ├── utils/                              # Mathematical, tax, and currency helpers
│   │   ├── currency_formatter.dart         # Indian Lakhs/Crores formatting (₹)
│   │   ├── date_formatter.dart             # Standardized date formatting
│   │   ├── gst_calculator.dart             # CGST/SGST/IGST/Round-off calculations
│   │   ├── number_to_words.dart            # Indian Rupee words conversion
│   │   └── validators.dart                 # Form validation (Email, GSTIN, Phone, PAN)
│   └── widgets/                            # Reusable UI component library
│       ├── app_button.dart                 # Primary, secondary, outline, text buttons
│       ├── app_text_field.dart             # Consistent text input fields
│       ├── empty_state_view.dart           # Empty state placeholders
│       ├── image_upload_card.dart          # Logo & signature upload cards
│       ├── kpi_card.dart                   # Dashboard metric tiles
│       ├── responsive_wrapper.dart         # Max-width layout container for Web/Tablet
│       ├── shimmer_loader.dart             # Skeleton loading animations
│       ├── signature_pad_dialog.dart       # Finger-drawn signature canvas
│       └── status_badge.dart               # Invoice status chips
├── features/                               # Domain feature modules
│   ├── auth/                               # Authentication & Business profile
│   │   ├── data/models/                    # UserModel, BusinessModel
│   │   ├── data/repositories/              # AuthRepository, BusinessNotifier
│   │   └── presentation/screens/           # LoginScreen, RegisterScreen, ForgotPasswordScreen
│   ├── onboarding/                         # First-time setup wizard
│   │   └── presentation/screens/           # BusinessSetupWizardScreen
│   ├── dashboard/                          # Home overview, KPIs, and charts
│   │   ├── data/models/                    # DashboardStats, MonthlyRevenue
│   │   └── presentation/screens/           # DashboardScreen
│   ├── invoices/                           # Invoicing core engine
│   │   ├── data/models/                    # InvoiceModel, InvoiceItemModel
│   │   ├── data/repositories/              # InvoiceRepository
│   │   ├── presentation/screens/           # CreateInvoiceWizardScreen, InvoiceListScreen,
│   │   │                                   # InvoiceDetailScreen, InvoicePreviewScreen
│   │   └── utils/                          # PdfInvoiceGenerator
│   ├── customers/                          # Customer CRM & client ledger
│   │   ├── data/models/                    # CustomerModel
│   │   ├── data/repositories/              # CustomerRepository
│   │   └── presentation/screens/           # CustomerListScreen, CustomerDetailScreen, CustomerFormScreen
│   ├── items/                              # Products & Services inventory
│   │   ├── data/models/                    # ItemModel
│   │   ├── data/repositories/              # ItemRepository
│   │   └── presentation/screens/           # ItemListScreen
│   ├── payments/                           # Payment recording & receipts
│   │   ├── data/models/                    # PaymentModel
│   │   └── presentation/screens/           # PaymentHistoryScreen, RecordPaymentBottomSheet, PaymentReceiptDialog
│   ├── reports/                            # Analytics, GST summaries & CSV export
│   │   ├── data/models/                    # ReportFilter, ComprehensiveReportData
│   │   ├── data/repositories/              # ReportsRepository
│   │   └── presentation/screens/           # ReportsScreen
│   ├── settings/                           # Business profile, Bank/UPI, App options
│   │   └── presentation/screens/           # BusinessProfileScreen, BankUpiSettingsScreen,
│   │                                       # AppSettingsScreen, MoreMenuScreen
│   └── templates/                          # Template styling & customizations
│       ├── data/models/                    # TemplateConfigModel
│       └── presentation/screens/           # TemplateSelectorScreen
├── navigation/                             # Routing infrastructure
│   ├── app_router.dart                     # GoRouter configuration & auth guards
│   └── main_shell_screen.dart              # Persistent 4-tab bottom navigation shell
└── test/                                   # Unit & widget test suites
    ├── features_test.dart
    ├── gst_calculator_test.dart
    ├── logo_and_signature_test.dart
    ├── user_status_and_auth_test.dart
    ├── widget_test.dart
    └── wizard_and_preview_test.dart
```

---

## 4. Database Schema & Supabase Setup

The application communicates with a Supabase PostgreSQL instance. Below is the complete SQL schema including table definitions, constraints, foreign keys, cascade rules, and Row Level Security (RLS) policies.

```sql
-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. BUSINESSES TABLE
CREATE TABLE IF NOT EXISTS public.businesses (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL DEFAULT 'My Business',
    legal_name VARCHAR(255),
    gstin VARCHAR(15),
    pan VARCHAR(10),
    email VARCHAR(255),
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100) NOT NULL DEFAULT 'Maharashtra',
    state_code VARCHAR(10) NOT NULL DEFAULT '27',
    pincode VARCHAR(10),
    logo_url TEXT,
    signature_url TEXT,
    upi_id VARCHAR(100),
    bank_name VARCHAR(150),
    bank_account_number VARCHAR(50),
    bank_ifsc VARCHAR(20),
    bank_branch VARCHAR(100),
    invoice_prefix VARCHAR(20) NOT NULL DEFAULT 'INV-',
    next_invoice_number INT NOT NULL DEFAULT 1001,
    currency VARCHAR(10) NOT NULL DEFAULT 'INR',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_user_business UNIQUE (user_id)
);

-- 3. CUSTOMERS TABLE
CREATE TABLE IF NOT EXISTS public.customers (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    company_name VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(20) NOT NULL,
    gstin VARCHAR(15),
    pan VARCHAR(10),
    billing_address TEXT,
    billing_city VARCHAR(100),
    billing_state VARCHAR(100) NOT NULL DEFAULT 'Maharashtra',
    billing_state_code VARCHAR(10) NOT NULL DEFAULT '27',
    billing_pincode VARCHAR(10),
    shipping_address TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. ITEMS (CATALOG) TABLE
CREATE TABLE IF NOT EXISTS public.items (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    sku VARCHAR(100),
    hsn_sac VARCHAR(20),
    unit VARCHAR(20) NOT NULL DEFAULT 'PCS',
    rate NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    tax_rate NUMERIC(5,2) NOT NULL DEFAULT 18.00,
    item_type VARCHAR(20) NOT NULL DEFAULT 'product',
    description TEXT,
    default_discount NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    is_tax_inclusive BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. INVOICES TABLE
CREATE TABLE IF NOT EXISTS public.invoices (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    invoice_number VARCHAR(100) NOT NULL,
    reference_number VARCHAR(100),
    po_number VARCHAR(100),
    invoice_title VARCHAR(100) NOT NULL DEFAULT 'TAX INVOICE',
    is_gst BOOLEAN NOT NULL DEFAULT TRUE,
    invoice_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    due_date TIMESTAMPTZ,
    customer_id BIGINT REFERENCES public.customers(id) ON DELETE SET NULL,
    customer_snapshot JSONB NOT NULL DEFAULT '{}'::jsonb,
    gst_type VARCHAR(20) NOT NULL DEFAULT 'intraState',
    place_of_supply VARCHAR(100),
    place_of_supply_state_code VARCHAR(10),
    subtotal NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    total_discount NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    taxable_amount NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    total_cgst NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    total_sgst NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    total_igst NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    round_off NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    grand_total NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    total_paid NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    balance_due NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    status VARCHAR(30) NOT NULL DEFAULT 'unpaid',
    notes TEXT,
    terms_and_conditions TEXT,
    template_id VARCHAR(50) NOT NULL DEFAULT 'classic',
    template_config JSONB NOT NULL DEFAULT '{}'::jsonb,
    pdf_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. INVOICE LINE ITEMS TABLE
CREATE TABLE IF NOT EXISTS public.invoice_items (
    id BIGSERIAL PRIMARY KEY,
    invoice_id BIGINT NOT NULL REFERENCES public.invoices(id) ON DELETE CASCADE,
    item_id BIGINT REFERENCES public.items(id) ON DELETE SET NULL,
    description TEXT NOT NULL,
    hsn_sac VARCHAR(20),
    quantity NUMERIC(10,2) NOT NULL DEFAULT 1.00,
    unit VARCHAR(20) NOT NULL DEFAULT 'PCS',
    rate NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    discount_rate NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    discount_amount NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    taxable_amount NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    tax_rate NUMERIC(5,2) NOT NULL DEFAULT 18.00,
    cgst_amount NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    sgst_amount NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    igst_amount NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    total_amount NUMERIC(12,2) NOT NULL DEFAULT 0.00
);

-- 7. PAYMENTS TABLE
CREATE TABLE IF NOT EXISTS public.payments (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    invoice_id BIGINT NOT NULL REFERENCES public.invoices(id) ON DELETE CASCADE,
    amount NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    method VARCHAR(50) NOT NULL DEFAULT 'upi',
    payment_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    transaction_id VARCHAR(100),
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. ROW LEVEL SECURITY (RLS) POLICIES
ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoice_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- Standard user-isolated RLS policies
CREATE POLICY "Users access own businesses" ON public.businesses
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users access own customers" ON public.customers
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users access own items" ON public.items
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users access own invoices" ON public.invoices
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users access own invoice_items" ON public.invoice_items
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.invoices
            WHERE invoices.id = invoice_items.invoice_id
            AND invoices.user_id = auth.uid()
        )
    );

CREATE POLICY "Users access own payments" ON public.payments
    FOR ALL USING (auth.uid() = user_id);

-- 9. SUPABASE STORAGE BUCKET CONFIGURATION
-- Bucket Name: business-assets
-- Set bucket to Public so generated PDFs can load public image URLs.
-- Storage paths convention:
--   users/{user_id}/logo.jpg
--   users/{user_id}/signature.png
```

---

## 5. Domain Rules & Business Logic

### 5.1 Indian GST Calculation Engine (`GstCalculator`)

The GST engine conforms to Central Board of Indirect Taxes and Customs (CBIC) rules:

1. **Supply Type Determination:**
   - **Intra-State:** Business State equals Customer Billing State (or Place of Supply State). Taxes applied: **CGST = TaxRate / 2**, **SGST = TaxRate / 2**, **IGST = 0**.
   - **Inter-State:** Business State differs from Customer Billing State (or Place of Supply State). Taxes applied: **IGST = TaxRate**, **CGST = 0**, **SGST = 0**.
   - **Handling "None / Not Applicable":** If customer billing state is `None`, `N/A`, or empty (e.g. export or cash sales), supply defaults safely to **Intra-State**.

2. **Line Item Math:**
   $$\text{Gross Amount} = \text{Quantity} \times \text{Rate}$$
   $$\text{Discount Amount} = \text{Gross Amount} \times \left(\frac{\text{Discount \%}}{100}\right) \quad \text{or Fixed Discount}$$
   $$\text{Taxable Amount} = \text{Gross Amount} - \text{Discount Amount}$$
   $$\text{Tax Amount} = \text{Taxable Amount} \times \left(\frac{\text{Tax Rate}}{100}\right)$$
   $$\text{Total Amount} = \text{Taxable Amount} + \text{Tax Amount}$$

3. **Non-GST / Bill of Supply Mode:**
   - When `isGst` is toggled off, `taxRate` is enforced to $0.0\%$.
   - CGST, SGST, and IGST amounts evaluate to $0.0$.
   - Invoice title dynamically changes from `"TAX INVOICE"` to `"BILL OF SUPPLY"` (or custom user-entered titles like `"PROFORMA INVOICE"` or `"ESTIMATE"`).

4. **Auto Round-Off & Balance Due:**
   - Grand Total is rounded to the nearest whole rupee: $\text{GrandTotal} = \text{round}(\text{ExactTotal})$.
   - The round-off differential is saved: $\text{RoundOff} = \text{GrandTotal} - \text{ExactTotal}$.
   - Balance due: $\text{BalanceDue} = \max(0.0, \text{GrandTotal} - \text{TotalPaid})$.

5. **Indian Numbering & Currency:**
   - Formatted using standard Indian comma separators: Hundreds, Thousands, Lakhs, Crores (e.g., `₹12,50,000.00`).
   - `NumberToWords`: Converts numeric total into words (e.g., *"Rupees Twelve Lakh Fifty Thousand Only"*).

---

### 5.2 Strict Image Processing & Single-File Storage Quotas

To minimize Supabase cloud storage costs and prevent app bloat:

1. **Client-Side Compression (`ImageCompressorService`):**
   - Pure Dart implementation using package `image` without native platform dependencies.
   - Max target size is strictly $\le 200\text{ KB}$.
   - **Logos:** Progressive JPEG encoding, iteratively stepping quality down ($85 \to 70 \to 55 \to 40$) and downscaling max dimensions to $\le 1024\text{ px}$.
   - **Signatures:** Transparent PNG encoding, iteratively resizing dimensions to preserve line crispness while staying under $200\text{ KB}$.

2. **Single-File Lifecycle (`SupabaseStorageService`):**
   - Strictly enforces **exactly one logo file** and **exactly one signature file** per user folder:
     - `users/{user_id}/logo.jpg`
     - `users/{user_id}/signature.png`
   - Before uploading a new file, all pre-existing files matching the pattern are deleted via `sb.storage.from('business-assets').remove(...)`.
   - Appends a timestamp query string `?t={milliseconds}` to public URLs to bust image caches in Flutter and web views.
   - Fallback to Base64 data URIs (`data:image/jpeg;base64,...`) when offline or in demo mode.

---

### 5.3 Account Health & Deletion Policy

Both `UserModel` and `BusinessModel` support `isActive` (`is_active`) and `isDeleted` (`is_deleted`):

- **Login Guard:** During `login()`, the business record is queried. If `is_deleted == true` or `is_active == false`, the session is immediately signed out (`signOut()`), local credentials wiped (`clearAll()`), and an explanatory exception is surfaced to the user.
- **Refresh Guard:** In `getActiveBusiness()`, if the remote record indicates deactivated or deleted status, the user is logged out immediately.

---

## 6. PDF Rendering Engine & Templates

The PDF generation module (`PdfInvoiceGenerator`) converts `InvoiceModel`, `BusinessModel`, and `TemplateConfigModel` into a high-resolution, vector-based A4 PDF document:

### Supported Templates:
1. **`classic`**: Clean, traditional corporate layout with bordered tables and colored headers.
2. **`modern`**: Minimalist header with bold typography and subtle dividing rules.
3. **`gst_detailed`**: Full regulatory compliance view with comprehensive CGST, SGST, IGST tax breakdown columns and HSN/SAC codes.
4. **`minimal`**: Compact, ink-friendly receipt layout.

### Advanced Features in PDF:
- **Embedded Fonts:** Uses `PdfGoogleFonts.robotoRegular()` and `PdfGoogleFonts.robotoBold()` with fallback to Helvetica.
- **Dynamic UPI QR Code:** Generates a scannable standard UPI intent string (`upi://pay?pa={upiId}&pn={businessName}&am={grandTotal}&cu=INR&tn=Invoice {invoiceNumber}`) rendered using `pw.BarcodeWidget`.
- **Multi-Source Image Resolver:** Reads Base64 data URIs, local `file://` paths, and remote HTTPS URLs using `Dio` byte streaming.
- **Amounts in Words:** Printed automatically at the bottom of the financial summary.
- **Bank & Remittance Box:** IFSC, Bank Name, Account Number, Branch, and UPI ID clearly organized.

---

## 7. State Management Architecture

State is managed cleanly via **Riverpod 3**:

| Provider | Type | Location | Purpose |
| :--- | :--- | :--- | :--- |
| `secureStorageServiceProvider` | `Provider` | `auth_repository.dart` | Global instance of `SecureStorageService` |
| `apiClientProvider` | `Provider` | `auth_repository.dart` | Global instance of `ApiClient` with auth interceptor |
| `authRepositoryProvider` | `Provider` | `auth_repository.dart` | Auth business logic and session status |
| `businessNotifierProvider` | `AsyncNotifierProvider` | `auth_repository.dart` | Active business profile state & reactive mutations |
| `invoiceRepositoryProvider` | `Provider` | `invoice_repository.dart` | Invoices database query engine |
| `dashboardStatsProvider` | `FutureProvider.autoDispose` | `dashboard_screen.dart` | Real-time aggregate KPIs for dashboard |
| `customerListProvider` | `FutureProvider.autoDispose` | `customer_list_screen.dart` | Filterable list of customers |
| `itemRepositoryProvider` | `Provider` | `item_repository.dart` | Product & service catalog operations |
| `reportsRepositoryProvider` | `Provider` | `reports_repository.dart` | Financial aggregations, tax slabs & CSV exports |
| `templateConfigProvider` | `NotifierProvider` | `invoice_preview_screen.dart` | Real-time PDF template customizations |

---

## 8. Navigation & Routing Structure

Navigation is powered by **GoRouter** with a persistent `StatefulShellRoute.indexedStack`:

```
/login (Public)
/register (Public)
/forgot-password (Public)
/onboarding (Protected Setup)

Bottom Navigation Tabs:
├── /dashboard       (Branch 0: KPIs, Quick Actions, Recent Invoices)
├── /invoices        (Branch 1: Searchable, Filterable Invoices List)
├── /customers       (Branch 2: Customer CRM & Outstanding Ledgers)
└── /more            (Branch 3: Catalog, Payments, Reports, Settings)

Deep & Floating Routes:
├── /create-invoice           (4-Step Stepper Wizard)
├── /invoices/:id             (Detailed breakdown, payment actions)
├── /invoices/:id/preview     (PDF Viewer, template switcher, sharing)
├── /customers/:id            (Customer profile & transaction ledger)
├── /items                    (Product & Service Catalog)
├── /payments                 (Payment recording history)
├── /reports                  (Sales, GST breakdown, CSV export)
├── /business-profile         (Company address, GSTIN, Logo, Signature)
├── /bank-settings            (Bank accounts & UPI VPA configuration)
├── /templates                (Invoice visual template editor)
└── /app-settings             (Prefixes, currency, default terms)
```

**Auth Redirect Logic:**
- If user session is active and healthy $\to$ redirect away from `/login`, `/register` to `/dashboard`.
- If user session is absent or expired $\to$ redirect all protected routes to `/login`.
- Monitored automatically using `GoRouterRefreshStream` hooked to `Supabase.instance.client.auth.onAuthStateChange`.

---

## 9. Design System & Theming

The visual identity follows a modern Indigo / Sky palette:

- **Primary Colors:**
  - `AppColors.primary`: `#4F46E5` (Indigo 600)
  - `AppColors.primaryDark`: `#3730A3` (Indigo 800)
  - `AppColors.primaryContainer`: `#EEF2FF` (Indigo 50)
- **Secondary / Accent Colors:**
  - `AppColors.secondary`: `#0EA5E9` (Sky 500)
  - `AppColors.accent`: `#8B5CF6` (Violet 500)
- **Financial Status Colors:**
  - `AppColors.success`: `#10B981` (Paid)
  - `AppColors.warning`: `#F59E0B` (Partial / Due soon)
  - `AppColors.error`: `#EF4444` (Overdue / Cancelled)
  - `AppColors.info`: `#3B82F6` (Draft)
- **Responsive Layout:**
  - `ResponsiveWrapper(maxWidth: 1080)` ensures the UI does not stretch awkwardly on iPad, Android Tablets, or Desktop Web, centering content gracefully.

---

## 10. Development Workflow & Commands

### 10.1 Environment Setup
1. **Flutter SDK:** Ensure Flutter $\ge 3.7.0$ is installed and added to your `PATH`.
2. **Dependencies:**
   ```bash
   flutter pub get
   ```
3. **Supabase Configuration:**
   Verify `lib/core/config/supabase_config.dart` contains your active Supabase URL and anon key:
   ```dart
   static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```

### 10.2 Running the Application
```bash
# Run on connected device or simulator
flutter run

# Run on Chrome (Web)
flutter run -d chrome

# Run on macOS desktop
flutter run -d macos
```

### 10.3 Testing & Quality Assurance
The codebase features a test suite covering GST calculations, currency formatting, number-to-words conversion, PDF generation, image compression, user status guards, and UI screen rendering:

```bash
# Run all tests
flutter test

# Run specific test suites
flutter test test/gst_calculator_test.dart
flutter test test/logo_and_signature_test.dart
flutter test test/user_status_and_auth_test.dart
flutter test test/wizard_and_preview_test.dart
flutter test test/features_test.dart

# Static analysis and linting
flutter analyze
```

### 10.4 Generating App Icons
App icons are configured for iOS, Android, and Web in `pubspec.yaml`:
```bash
flutter pub run flutter_launcher_icons
```

### 10.5 Building for Production
```bash
# Build Android APK
flutter build apk --release

# Build Android App Bundle (Play Store)
flutter build appbundle --release

# Build iOS IPA (Requires macOS & Xcode)
flutter build ipa --release

# Build Web distribution
flutter build web --release
```

---

## 11. Developer Conventions & Rules

1. **State Immutability:** Always use immutable models (`@immutable` / `const` constructors) with `copyWith()` for modifications. Never mutate object properties in-place.
2. **Tax Calculations:** Never perform manual GST or round-off math directly in UI widgets. Always delegate to `GstCalculator.calculateLineItem()` and `GstCalculator.calculateInvoiceTotals()`.
3. **Asset Uploads:** Always pass images through `ImageCompressorService.compressImage()` before uploading to Supabase Storage or converting to Base64.
4. **Storage Cleanliness:** Never upload orphaned files. Always invoke `SupabaseStorageService` which cleans up existing files before upserting.
5. **Form Validation:** Use `Validators` class for email, phone, GSTIN, and PAN checks to ensure data integrity across inputs.
6. **Error Handling:** Catch network exceptions gracefully, map them to human-readable error messages, and display them using `ScaffoldMessenger.of(context).showSnackBar()`.

---

## 12. Task Tracking & Ongoing Activity Log

Every completed development task, architectural change, or schema update must be logged here.

| Date & Timestamp | Task / Change Summary | Files Affected | Status |
| :--- | :--- | :--- | :--- |
| **2026-11-07** | Initialized `gemini.md` knowledge base; documented full tech stack, directory blueprint, Supabase SQL DDL, GST business logic, PDF generation engine, state management, and developer workflow. | `gemini.md` | ✅ Completed |
| **2026-11-07** | Added mandatory AI operational directives and initialized the living Task Tracking & Activity Log. | `gemini.md` | ✅ Completed |
| **2026-11-07** | **Code Audit, Vulnerability Mitigation & Full QA Testing Suite:**<br>1. Resolved `TemplateSelectorScreen` mobile layout overflow by implementing adaptive `LayoutBuilder` (tabs on mobile, split-screen on desktop).<br>2. Fixed template preview crash for new accounts by adding fallback sample invoice.<br>3. Unified `TemplateConfigNotifier` into `template_config_provider.dart` eliminating duplicate providers.<br>4. Re-enabled `Invoice Templates` navigation option in `more_menu_screen.dart`.<br>5. Corrected invalid navigation route `/invoices/create` $\to$ `/create-invoice` in `invoice_list_screen.dart` and added defensive alias route in `app_router.dart`.<br>6. Resolved Dropdown RenderFlex overflow and crash vulnerability in `customer_form_screen.dart` across all 28 states & UTs.<br>7. Fixed CSV RFC-4180 quote escaping in `reports_repository.dart`.<br>8. Added validation guards in `item_list_screen.dart` and defensive checks in `record_payment_bottom_sheet.dart`.<br>9. Created 4 new automated test suites (`test/template_selector_and_config_test.dart`, `test/customer_form_and_states_test.dart`, `test/csv_export_and_escaping_test.dart`, `test/payment_recording_test.dart`). Verified all 37 tests pass with 0 errors and 0 analyzer warnings. | `template_selector_screen.dart`, `template_config_provider.dart`, `invoice_preview_screen.dart`, `more_menu_screen.dart`, `invoice_list_screen.dart`, `app_router.dart`, `customer_form_screen.dart`, `item_list_screen.dart`, `reports_repository.dart`, `record_payment_bottom_sheet.dart`, `test/` | ✅ Completed |
| **2026-11-07** | Prepared Google Play Store listing metadata, including 80-character official Play Console Short Description and high-converting 80-word promotional descriptions tailored for Indian SMEs and GST invoicing. | `gemini.md` | ✅ Completed |
| **2026-11-07** | Authored comprehensive, SEO-optimized Google Play Store Full Description ($\le 4,000$ characters) detailing GST compliance, Non-GST Bill of Supply, UPI QR code payments, client CRM, multi-template PDF engine, and financial analytics. | `gemini.md` | ✅ Completed |
| **2026-11-07** | **Audit, Stabilization & Full Enhancement of `customer_form_screen.dart`:**<br>1. Created and exported `CustomerFormScreen` alongside `CustomerFormBottomSheet` so the file can be rendered both as a modal bottom sheet and as a standalone full-screen route without missing class errors.<br>2. Added defensive state management: Introduced `_isLoading` flag on save actions and bound to `AppButton(isLoading: _isLoading)` to eliminate duplicate rapid-tap submissions.<br>3. Wrapped `_handleSave` in robust `try-catch-finally` with user-friendly `SnackBar` alerts, preventing unhandled async exceptions or app freezing when network or Supabase errors occur.<br>4. Preserved existing customer data on updates (`pan`, `billingPincode`, `shippingAddress`, `totalSales`, `totalPaid`, `outstandingAmount`, `createdAt`) so updating basic info doesn't overwrite auxiliary fields to null.<br>5. Added dual invalidation: Invalidates both `customerListProvider` and `customerDetailProvider(id)` when updating.<br>6. Resolved Dropdown code formatting so "None / Not Applicable" displays cleanly without empty parenthesis `()`, and enhanced Billing Address with `maxLines: 2`.<br>7. Added Edit Customer action in `CustomerDetailScreen` AppBar, resolving unused import warnings. All 38 automated tests pass with 0 analyzer issues. | `customer_form_screen.dart`, `customer_detail_screen.dart`, `test/customer_form_and_states_test.dart`, `gemini.md` | ✅ Completed |

---

## 13. Comprehensive Testing Scenarios & QA Checklist

Below is the verification checklist and test scenario coverage for Invoicify:

### 13.1 Authentication & Session Security
- [x] **Valid Login:** User successfully signs in with valid credentials, receives JWT, and is routed to `/dashboard`.
- [x] **Invalid Login:** Shows error SnackBar on invalid credentials or unconfirmed email without crashing.
- [x] **Account Deactivation Guard:** If `is_active == false` or `is_deleted == true`, immediately terminates session, wipes local storage, and shows rejection message.
- [x] **Token Persistence:** JWT and refresh tokens stored securely in `FlutterSecureStorage`.
- [x] **Sign Out:** Wipes all secure storage and SharedPreferences cache, routing user to `/login`.

### 13.2 Customer CRM & Ledgers
- [x] **Customer Creation:** Validates mandatory Name and 10-digit mobile number.
- [x] **GSTIN Validation:** Validates Indian 15-character GSTIN format if provided; accepts unregistered buyers when empty.
- [x] **State & UT Dropdown Safety:** Supports all 28 Indian States and 8 UTs (plus "None / Not Applicable"); prevents dropdown assertion errors.
- [x] **Live Ledger Aggregation:** Automatically calculates `totalSales`, `totalPaid`, and `outstandingAmount` based on linked invoice records.

### 13.3 Product & Service Catalog
- [x] **Item Creation:** Validates item name and non-negative rate; supports HSN/SAC codes, standard GST slabs (0%, 5%, 12%, 18%, 28%), and units (PCS, NOS, HRS, etc.).
- [x] **Search Filtering:** Live case-insensitive search by item name, SKU, or HSN/SAC code.

### 13.4 GST & Non-GST Invoicing Engine
- [x] **Intra-State Split:** Auto-calculates CGST (TaxRate / 2) and SGST (TaxRate / 2) when business state equals customer state.
- [x] **Inter-State Tax:** Applies full IGST when customer or place of supply state differs from business state.
- [x] **Non-GST / Bill of Supply:** Forces tax rate to 0.0%, dynamically renames document to "BILL OF SUPPLY" (or custom title), and allows null due dates/place of supply.
- [x] **Item & Invoice Discounts:** Accurately subtracts line item percentage or fixed discounts before tax computation.
- [x] **Auto Round-Off:** Accurately rounds grand total to nearest integer and records the differential in `round_off`.
- [x] **Mandatory Authorized Signature:** Enforces authorized signature upload or canvas drawing before finalizing invoice.

### 13.5 Payments & Settlements
- [x] **Record Payment:** Updates `total_paid` and clamps `balance_due` $\ge 0.0$.
- [x] **Status Progression:** Automatically transitions invoice status from `unpaid` $\to$ `partiallyPaid` $\to$ `paid`.
- [x] **Payment Receipts:** Generates instant payment receipt dialog with transaction ID and payment method.

### 13.6 PDF Generation & Template Customizer
- [x] **Vector PDF Canvas:** Renders high-resolution vector PDF across all 4 templates (`classic`, `modern`, `gst_detailed`, `minimal`).
- [x] **Scannable UPI QR Code:** Generates valid dynamic `upi://pay` BarcodeWidget on document.
- [x] **Fallback Sample Preview:** Renders sample invoice when custom invoice ID is unavailable so preview never fails.
- [x] **Responsive Adaptation:** Tabbed layout on mobile devices (<768px), side-by-side split view on tablet/desktop ($\ge 768\text{ px}$).

### 13.7 Financial Reports & CSV Export
- [x] **GST Tax Slab Aggregation:** Correctly breaks down taxable sums and taxes across 0%, 5%, 12%, 18%, and 28% slabs.
- [x] **RFC-4180 CSV Escaping:** Escapes double quotes (`""`), commas, and line breaks in customer names, company names, and invoice numbers.
- [x] **Shareable Summary:** Generates structured WhatsApp/Email text summary.

### 13.8 Asset Storage Optimization
- [x] **Strict Size Quota:** Pure Dart compression guarantees all logos and signatures are strictly $\le 200\text{ KB}$.
- [x] **Single-File Lifecycle:** Deletes existing user files before upload to prevent orphaned storage bloat.
- [x] **Cache Busting:** Appends `?t={timestamp}` to image URLs.

---

*This document serves as the single source of truth for the architecture, business rules, database schema, and workflows of the Invoicify codebase.*

