// lib/core/app/app_router.dart
import 'package:flutter/material.dart';
import 'package:attendance_app/features/member/screens/members_list_screen.dart';
import 'package:attendance_app/features/event/screens/events_list_screen.dart';
import 'package:attendance_app/features/member/screens/member_create_screen.dart';
import 'package:attendance_app/features/member/screens/member_view_screen.dart';
import 'package:attendance_app/features/member/screens/member_edit_screen.dart';
import 'package:attendance_app/features/member/models/member.dart';
import 'package:attendance_app/features/event/screens/event_create_screen.dart';
import 'package:attendance_app/features/event/screens/event_view_screen.dart';
import 'package:attendance_app/features/event/screens/event_edit_screen.dart';
import 'package:attendance_app/features/event/models/event.dart';
import 'package:attendance_app/features/event_organization/screens/event_organizations_list_screen.dart';
import 'package:attendance_app/features/event_organization/screens/event_organization_create_screen.dart';
import 'package:attendance_app/features/event_organization/screens/event_organization_edit_screen.dart';
import 'package:attendance_app/features/event_organization/screens/event_organization_view_screen.dart';
import 'package:attendance_app/features/event_organization/models/event_organization.dart';
import 'package:attendance_app/features/event_organization/screens/event_organization_participants_screen.dart';
import 'package:attendance_app/core/widgets/error_page.dart';
import 'package:attendance_app/core/widgets/app_layout.dart';
import 'package:attendance_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:attendance_app/features/settings/screens/settings_screen.dart';
import 'package:attendance_app/features/settings/screens/google_account_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case '/members':
        return MaterialPageRoute(builder: (_) => const MembersListScreen());
      case '/members/create':
        return MaterialPageRoute(builder: (_) => const MemberCreateScreen());
      case '/members/view':
        final member = settings.arguments as Member;
        return MaterialPageRoute(
          builder: (_) => MemberViewScreen(member: member),
        );
      case '/members/edit':
        final member = settings.arguments as Member;
        return MaterialPageRoute(
          builder: (_) => MemberEditScreen(member: member),
        );
      case '/events':
        return MaterialPageRoute(builder: (_) => const EventsListScreen());
      case '/events/create':
        return MaterialPageRoute(builder: (_) => const EventCreateScreen());
      case '/events/view':
        final event = settings.arguments as Event;
        return MaterialPageRoute(builder: (_) => EventViewScreen(event: event));
      case '/events/edit':
        final event = settings.arguments as Event;
        return MaterialPageRoute(builder: (_) => EventEditScreen(event: event));
      case '/event-organizations':
        return MaterialPageRoute(
          builder: (_) => const EventOrganizationsListScreen(),
        );
      case '/event-organizations/create':
        final event = settings.arguments as Event?;
        return MaterialPageRoute(
          builder: (_) => EventOrganizationCreateScreen(event: event),
        );
      case '/event-organizations/view':
        final org = settings.arguments as EventOrganization;
        return MaterialPageRoute(
          builder: (_) => EventOrganizationViewScreen(eventOrganization: org),
        );
      case '/event-organizations/edit':
        final org = settings.arguments as EventOrganization;
        return MaterialPageRoute(
          builder: (_) => EventOrganizationEditScreen(eventOrganization: org),
        );
      case '/event-organization/participants':
        final args = settings.arguments as Map;
        final eventOrganizationId = args['eventOrganizationId'] as String;
        final eventOrganization =
            args['eventOrganization'] as EventOrganization?;
        return MaterialPageRoute(
          builder: (_) => EventOrganizationParticipantsScreen(
            eventOrganizationId: eventOrganizationId,
            eventOrganization: eventOrganization,
          ),
        );
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case '/google-account':
        return MaterialPageRoute(builder: (_) => const GoogleAccountScreen());
      case '/error':
        final message = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => AppLayout(
            title: 'Erreur',
            body: ErrorPage(message: message),
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => AppLayout(title: 'Erreur', body: const ErrorPage()),
        );
    }
  }
}
