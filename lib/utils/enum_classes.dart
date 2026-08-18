import 'package:flutter/material.dart';

// ================= ENUM =================
enum ButtonVariant { filled, outline, ghost }
enum AppType {
  gym,
  shop,
  institute,
  salon,
  hospital,
  restaurant,
  finance,
  realEstate,
  generic,
}
// ================= SUBSCRIPTION =================
enum SubscriptionStatus {
  active,
  expired,
  cancelled,
  paused,
  trial,
  grace,
}

// ================= PAYMENT =================
enum PaymentStatus {
  paid,
  pending,
  failed,
  refunded,
}

AppType mapStringToAppType(String? type) {
  final t = (type ?? "").toLowerCase().trim();

  switch (t) {

  // =========================================================
  // GYM / FITNESS
  // Workflow:
  // Members, memberships, trainers, attendance, workout plans
  // =========================================================

    case "gym":
    case "fitness center":
    case "fitness centre":
    case "fitness club":
    case "health club":
    case "workout center":
    case "workout centre":
    case "fitness studio":
    case "fitness center":
    case "crossfit":
    case "crossfit gym":
    case "bodybuilding gym":
    case "bodybuilding":
    case "personal training":
    case "personal trainer":
    case "pt studio":
    case "strength training":
    case "weight training":
    case "fitness training":
    case "functional training":
    case "functional fitness":
    case "zumba":
    case "zumba studio":
    case "aerobics":
    case "aerobics center":
    case "aerobics centre":
    case "pilates":
    case "pilates studio":
    case "yoga":
    case "yoga center":
    case "yoga centre":
    case "yoga studio":
    case "boxing gym":
    case "boxing club":
    case "boxing":
    case "martial arts":
    case "martial arts center":
    case "martial arts centre":
    case "karate":
    case "karate center":
    case "karate centre":
      return AppType.gym;


  // =========================================================
  // SHOP / RETAIL
  // Workflow:
  // Customers, products, stock, sales, invoices, payments
  // =========================================================

    case "shop":
    case "store":
    case "general store":
    case "general shop":
    case "retail":
    case "retail store":
    case "retail shop":
    case "grocery":
    case "grocery store":
    case "grocery shop":
    case "supermarket":
    case "super market":
    case "hypermarket":
    case "hyper market":
    case "department store":
    case "departmental store":
    case "mart":
    case "supermart":
    case "super mart":
    case "super store":
    case "superstore":
    case "mini mart":
    case "minimart":
    case "convenience store":
    case "convenience shop":
    case "shopping store":
    case "shopping center":
    case "shopping centre":
    case "shopping mall":
    case "mall":
    case "market":
    case "local market":
    case "local shop":
    case "kirana":
    case "kirana store":
    case "kirana shop":
    case "provision store":
    case "provision shop":
    case "provisions":
    case "wholesale":
    case "wholesale store":
    case "wholesale shop":
    case "wholesaler":
    case "retailer":
    case "retail business":
    case "distributor":
    case "distributorship":

    // Electronics / mobile
    case "mobile shop":
    case "mobile store":
    case "electronics shop":
    case "electronics store":
    case "computer shop":
    case "computer store":
    case "laptop shop":
    case "laptop store":

    // Fashion
    case "clothing store":
    case "clothing shop":
    case "garment store":
    case "garments":
    case "fashion store":
    case "fashion shop":
    case "boutique":
    case "shoe store":
    case "footwear store":
    case "footwear shop":

    // Jewellery
    case "jewellery store":
    case "jewelry store":
    case "jewellery shop":
    case "jewelry shop":

    // Other retail
    case "gift shop":
    case "toy store":
    case "toy shop":
    case "book store":
    case "bookshop":
    case "stationery store":
    case "stationery shop":
    case "pet shop":
    case "pet store":
    case "hardware store":
    case "hardware shop":
    case "paint shop":
    case "paint store":
    case "sanitary store":
    case "electrical shop":
    case "electrical store":
    case "building material store":
    case "building materials":
    case "auto parts shop":
    case "auto parts store":
    case "spare parts shop":
    case "spare parts store":
    case "car accessories":
    case "bike accessories":

    // Medical RETAIL
    // Important: pharmacy sells products, so it remains SHOP.
    case "pharmacy":
    case "chemist":
    case "chemist shop":
    case "medical store":
    case "medical shop":
    case "drug store":
    case "medicine shop":
      return AppType.shop;


  // =========================================================
  // INSTITUTE / EDUCATION
  // Workflow:
  // Students, batches, courses, fees, attendance, teachers
  // =========================================================

    case "institute":
    case "institution":
    case "educational institute":
    case "educational institution":
    case "education center":
    case "education centre":
    case "educational center":
    case "educational centre":
    case "learning center":
    case "learning centre":

    // Schools
    case "school":
    case "public school":
    case "private school":
    case "primary school":
    case "secondary school":
    case "high school":
    case "higher secondary school":
    case "senior secondary school":
    case "international school":
    case "boarding school":

    // Higher education
    case "college":
    case "degree college":
    case "university":
    case "campus":

    // Academy / training
    case "academy":
    case "educational academy":
    case "training academy":
    case "training institute":
    case "training center":
    case "training centre":
    case "technical institute":
    case "technical training":
    case "vocational institute":
    case "vocational training":
    case "skill center":
    case "skill centre":
    case "skill development center":
    case "skill development centre":

    // Coaching / tuition
    case "coaching":
    case "coaching center":
    case "coaching centre":
    case "coaching institute":
    case "coaching academy":
    case "tuition":
    case "tuition center":
    case "tuition centre":
    case "tuition classes":
    case "tutorial":
    case "tutorial center":
    case "tutorial centre":
    case "classes":
    case "class":

    // Computer / IT education
    case "computer institute":
    case "computer classes":
    case "computer training":
    case "computer training center":
    case "coding institute":
    case "coding academy":
    case "coding classes":
    case "programming institute":
    case "programming academy":
    case "it institute":
    case "it training":
    case "software training institute":
    case "software training":

    // Language education
    case "language institute":
    case "language center":
    case "language centre":
    case "english classes":
    case "english academy":
    case "spoken english":
    case "ielts institute":
    case "ielts coaching":
    case "language school":

    // Competitive exams
    case "competitive exam":
    case "exam coaching":
    case "entrance coaching":
    case "neet coaching":
    case "jee coaching":
    case "upsc coaching":
    case "ssc coaching":
    case "banking coaching":
    case "government exam coaching":

    // Kids education
    case "preschool":
    case "pre school":
    case "playschool":
    case "play school":
    case "kindergarten":
    case "montessori":
    case "daycare":
    case "day care":
    case "childcare":
      return AppType.institute;


  // =========================================================
  // SALON / BEAUTY
  // Workflow:
  // Clients, appointments, services, staff, packages
  // =========================================================

    case "salon":
    case "beauty salon":
    case "hair salon":
    case "hair studio":
    case "hairdresser":
    case "barber":
    case "barber shop":
    case "barbershop":
    case "men's salon":
    case "mens salon":
    case "women's salon":
    case "womens salon":
    case "unisex salon":
    case "beauty parlour":
    case "beauty parlor":
    case "beauty studio":
    case "beauty center":
    case "beauty centre":
    case "spa":
    case "day spa":
    case "wellness spa":
    case "nail salon":
    case "nail studio":
    case "makeup studio":
    case "makeup artist":
    case "makeup salon":
    case "bridal makeup":
    case "bridal studio":
    case "skin care":
    case "skincare":
    case "hair care":
    case "hair care center":
    case "hair care centre":
    case "hair treatment":
    case "grooming":
    case "grooming center":
    case "grooming centre":
    case "men grooming":
    case "beauty and wellness":
      return AppType.salon;


  // =========================================================
  // HOSPITAL / MEDICAL / HEALTHCARE
  // Workflow:
  // PATIENTS, doctors, appointments, treatments, medical records
  //
  // Important:
  // Medical Store / Pharmacy is NOT here.
  // Pharmacy = Shop because its workflow is retail.
  // =========================================================

    case "hospital":
    case "private hospital":
    case "government hospital":
    case "general hospital":
    case "specialty hospital":
    case "speciality hospital":
    case "multi specialty hospital":
    case "multispecialty hospital":
    case "medical":
    case "medical center":
    case "medical centre":
    case "medical clinic":
    case "clinic":
    case "health clinic":
    case "health center":
    case "health centre":
    case "healthcare":
    case "health care":
    case "healthcare center":
    case "healthcare centre":
    case "health service":
    case "doctor":
    case "doctor clinic":
    case "doctor's clinic":
    case "physician":
    case "general physician":
    case "specialist":
    case "medical practitioner":
    case "medical practice":

    // Dental
    case "dental clinic":
    case "dental":
    case "dentist":
    case "dental hospital":
    case "dental care":

    // Orthopedic
    case "orthopedic":
    case "orthopedic clinic":
    case "orthopaedic":
    case "orthopaedic clinic":
    case "orthopedic center":
    case "orthopaedic center":

    // Dermatology
    case "dermatology":
    case "dermatologist":
    case "dermatology clinic":
    case "skin clinic":
    case "skin hospital":

    // Cardiology
    case "cardiology":
    case "cardiology clinic":
    case "heart clinic":
    case "heart hospital":

    // Neurology
    case "neurology":
    case "neurology clinic":
    case "neurologist":

    // Pediatrics
    case "pediatrics":
    case "paediatrics":
    case "pediatric clinic":
    case "paediatric clinic":
    case "child clinic":
    case "children hospital":

    // Gynecology
    case "gynecology":
    case "gynaecology":
    case "gynecology clinic":
    case "gynaecology clinic":
    case "women's clinic":
    case "womens clinic":

    // Physiotherapy
    case "physiotherapy":
    case "physiotherapy center":
    case "physiotherapy centre":
    case "physio clinic":
    case "physiotherapist":

    // Diagnostics / Labs
    case "pathology":
    case "pathology lab":
    case "diagnostic center":
    case "diagnostic centre":
    case "diagnostics":
    case "diagnostic lab":
    case "laboratory":
    case "lab":
    case "medical laboratory":
    case "testing laboratory":

    // Nursing / home healthcare
    case "nursing home":
    case "nursing center":
    case "nursing centre":
    case "nursing care":
    case "home healthcare":
    case "home health":
    case "home nursing":
    case "home nursing care":
      return AppType.hospital;


  // =========================================================
  // RESTAURANT / FOOD
  // Workflow:
  // Customers, tables, orders, menu, bills, kitchen
  // =========================================================

    case "restaurant":
    case "restaurants":
    case "food":
    case "food business":
    case "food outlet":
    case "food joint":
    case "food court":
    case "eatery":
    case "diner":
    case "cafe":
    case "café":
    case "coffee shop":
    case "coffee house":
    case "coffee cafe":
    case "fast food":
    case "fast food restaurant":
    case "quick service restaurant":
    case "qsr":
    case "fine dining":
    case "casual dining":
    case "family restaurant":
    case "buffet restaurant":
    case "dhaba":
    case "hotel restaurant":
    case "bakery":
    case "bakery shop":
    case "cake shop":
    case "cake bakery":
    case "sweet shop":
    case "sweets":
    case "mithai shop":
    case "confectionery":
    case "dessert shop":
    case "ice cream shop":
    case "ice cream parlour":
    case "ice cream parlor":
    case "ice cream cafe":
    case "juice shop":
    case "juice bar":
    case "smoothie bar":
    case "snack shop":
    case "snacks":
    case "street food":
    case "food truck":
    case "tiffin":
    case "tiffin service":
    case "catering":
    case "catering service":
    case "cloud kitchen":
    case "home kitchen":
    case "mess":
    case "canteen":
    case "canteen service":
    case "meal service":
      return AppType.restaurant;


  // =========================================================
  // FINANCE
  // Workflow:
  // Clients, accounts, loans, investments, policies,
  // payments, transactions, financial records
  // =========================================================

    case "finance":
    case "financial":
    case "financial services":
    case "finance company":
    case "financial company":
    case "bank":
    case "banking":
    case "bank branch":
    case "credit union":
    case "microfinance":
    case "micro finance":
    case "loan":
    case "loan agency":
    case "loan service":
    case "loan company":
    case "loan consultant":
    case "finance consultant":
    case "financial consultant":
    case "financial consultancy":
    case "insurance":
    case "insurance agency":
    case "insurance company":
    case "insurance agent":
    case "investment":
    case "investment firm":
    case "investment company":
    case "mutual fund":
    case "mutual funds":
    case "stock broker":
    case "stock brokerage":
    case "broker":
    case "brokerage":
    case "trading":
    case "trading company":
    case "accounting":
    case "accountant":
    case "accounting firm":
    case "ca":
    case "chartered accountant":
    case "tax consultant":
    case "tax consultancy":
    case "tax services":
    case "auditor":
    case "audit firm":
    case "financial advisor":
    case "financial adviser":
    case "wealth management":
    case "wealth management company":
    case "money transfer":
    case "money exchange":
    case "currency exchange":
      return AppType.finance;


  // =========================================================
  // REAL ESTATE
  // Workflow:
  // Leads, properties, site visits, buyers, tenants,
  // owners, deals, rent, property management
  // =========================================================

    case "real estate":
    case "realestate":
    case "real estate agency":
    case "real estate agent":
    case "real estate broker":
    case "property":
    case "property dealer":
    case "property dealers":
    case "property agency":
    case "property agent":
    case "property broker":
    case "property brokerage":
    case "estate agent":
    case "estate agency":
    case "property consultant":
    case "property consultancy":
    case "real estate consultant":
    case "real estate consultancy":
    case "property management":
    case "property management company":
    case "rental property":
    case "rental agency":
    case "rental services":
    case "housing":
    case "housing agency":
    case "housing company":
    case "apartment management":
    case "commercial property":
    case "commercial real estate":
    case "residential property":
    case "residential real estate":

    // Builders / Developers
    case "builder":
    case "builders":
    case "building company":
    case "developer":
    case "property developer":
    case "real estate developer":
    case "construction":
    case "construction company":
    case "construction contractor":
    case "contractor":
    case "civil contractor":
    case "infrastructure":
    case "infrastructure company":
      return AppType.realEstate;


  // =========================================================
  // UNKNOWN
  // =========================================================

    default:
      return AppType.generic;
  }
}
class DashboardText {

  static String title(AppType type) {
    switch (type) {
      case AppType.gym:
        return "Gym Dashboard";
      case AppType.shop:
        return "Shop Dashboard";
      case AppType.institute:
        return "Institute Dashboard";
      case AppType.salon:
        return "Salon Dashboard";
      case AppType.hospital:
        return "Hospital Dashboard";
      case AppType.restaurant:
        return "Restaurant Dashboard";
      case AppType.finance:
        return "Finance Dashboard";
      case AppType.realEstate:
        return "Real Estate Dashboard";
      case AppType.generic:
        return "Business Dashboard";
    }
  }
static String searchBarTitle(AppType type) {
    switch (type) {
      case AppType.gym:
        return "Search Member";
      case AppType.shop:
        return "Search Customer";
      case AppType.institute:
        return "Search Student";
      case AppType.salon:
        return "Search Client";
      case AppType.hospital:
        return "Search Patient";
      case AppType.restaurant:
        return "Search Customer";
      case AppType.finance:
        return "Search Client";
      case AppType.realEstate:
        return "Search Client";
      case AppType.generic:
        return "Search...";
    }
  }

  static String prsSearchCustomer(AppType type) {
    switch (type) {
      case AppType.gym:
        return "Search Or Enter Member Name";
      case AppType.shop:
        return "Search Or Enter Customer Name";
      case AppType.institute:
        return "Search Or Enter Student Name";
      case AppType.salon:
        return "Search Or Enter Client Name";
      case AppType.hospital:
        return "Search Or Enter Patient Name";
      case AppType.restaurant:
        return "Search Or Enter Customer Name";
      case AppType.finance:
        return "Search Or Enter Client Name";
      case AppType.realEstate:
        return "Search Or Enter Client Name";
      case AppType.generic:
        return "Search Or Enter Name...";
    }
  }

  static String customerName(AppType type) {
    switch (type) {
      case AppType.gym:
        return "Member Name";
      case AppType.shop:
        return "Customer Name";
      case AppType.institute:
        return "Student Name";
      case AppType.salon:
        return "Client Name";
      case AppType.hospital:
        return "Patient Name";
      case AppType.restaurant:
        return "Customer Name";
      case AppType.finance:
        return "Client Name";
      case AppType.realEstate:
        return "Client Name";
      case AppType.generic:
        return "Name";
    }
  } static String customer(AppType type) {
    switch (type) {
      case AppType.gym:
        return "Member";
      case AppType.shop:
        return "Customer";
      case AppType.institute:
        return "Student";
      case AppType.salon:
        return "Client";
      case AppType.hospital:
        return "Patient";
      case AppType.restaurant:
        return "Customer";
      case AppType.finance:
        return "Client";
      case AppType.realEstate:
        return "Client";
      case AppType.generic:
        return "Customer";
    }
  }

  static List<String> metrics(AppType type) {
    switch (type) {
      case AppType.gym:
        return ["Members", "Active Plans", "Pending Fees", "Expiring Soon"];
      case AppType.shop:
        return ["Customers", "Orders", "Pending Payments", "Low Stock"];
      case AppType.institute:
        return ["Students", "Active Courses", "Pending Fees", "Classes Today"];
      case AppType.salon:
        return ["Clients", "Appointments", "Pending Payments", "Bookings"];
      case AppType.hospital:
        return ["Patients", "Appointments", "Bills", "Doctors"];
      case AppType.restaurant:
        return ["Orders", "Tables", "Bills", "Revenue"];
      case AppType.finance:
        return ["Clients", "Transactions", "Pending", "Reports"];
      case AppType.realEstate:
        return ["Leads", "Properties", "Deals", "Visits"];
      case AppType.generic:
        return ["Users", "Activity", "Pending", "Alerts"];
    }
  }

  static List<String> actions(AppType type) {
    switch (type) {
      case AppType.gym:
        return ["Member", "Income", "Expense", "Calculator"];
      case AppType.shop:
        return ["Customer", "Income", "Expense", "Calculator"];
      case AppType.institute:
        return ["Student", "Income", "Expense", "Calculator"];
      case AppType.salon:
        return ["Client", "Income", "Expense", "Calculator"];
      case AppType.hospital:
        return ["Patient", "Income", "Expense", "Calculator"];
      case AppType.restaurant:
        return ["Customer", "Income", "Expense", "Calculator"];
      case AppType.finance:
        return ["Client", "Income", "Expense", "Calculator"];
      case AppType.realEstate:
        return ["Client", "Income", "Expense", "Calculator"];
      case AppType.generic:
        return ["Add", "Income", "Expense", "Calculator"];
    }
  }

  static IconData getIcon(AppType type) {
    switch (type) {
      case AppType.gym:
        return Icons.fitness_center;
      case AppType.shop:
        return Icons.store;
      case AppType.institute:
        return Icons.school;
      case AppType.salon:
        return Icons.cut;
      case AppType.hospital:
        return Icons.local_hospital;
      case AppType.restaurant:
        return Icons.restaurant;
      case AppType.finance:
        return Icons.attach_money;
      case AppType.realEstate:
        return Icons.home;
      case AppType.generic:
        return Icons.business;
    }
  }
}