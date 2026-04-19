class Routes {
  Routes._();

  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const onboarding = '/onboarding';
  static const shell = '/app';
  static const dashboard = '/app/dashboard';
  static const map = '/app/map';
  static const parcels = '/app/parcels';
  static const alerts = '/app/alerts';
  static const settings = '/app/settings';

  static const parcelDetails = '/parcel'; // /parcel/:id
  static const addParcel = '/add-parcel';
  static const editParcel = '/edit-parcel';
  static const observation = '/observation'; // /observation/:parcelId
  static const checklist = '/checklist'; // /checklist/:parcelId
  static const recommendations = '/recommendations'; // /recommendations/:parcelId
  static const reports = '/reports';
  static const reportPreview = '/reports/preview';
  static const routePlanner = '/route-planner';
}
