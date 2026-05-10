// lib/core/network/endpoints.dart
// All API endpoint paths — single place to update

class Endpoints {
  // Production backend (Render)
  static const baseUrl = 'http://127.0.0.1:8001'; // Local backend for testing
  
  // Auth
  static const authInit = '/api/v1/auth/anonymous-init';
  static const billingRestore = '/api/v1/billing/restore';

  // AI Generation (Stateless — Zero-Knowledge)
  static const planGenerate = '/api/v1/plan/generate';
  static const reportWeekly = '/api/v1/report/weekly-analyze';

  // Photo
  static const photoAnalyze = '/api/v1/photo/analyze';

  // Reference data
  static const ingredients = '/api/v1/ingredients';
  static const interactions = '/api/v1/interactions';

  // Shopping list
  static const shoppingList = '/api/v1/shopping-list';
  static const shoppingListGenerate = '/api/v1/shopping-list/generate';

  // Subscription
  static const subscriptionStatus = '/api/v1/subscription/status';

  // Push
  static const pushRegister = '/api/v1/push/register';
  static const pushSettings = '/api/v1/push/settings';
}
