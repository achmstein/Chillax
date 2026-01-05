import {
  LayoutDashboard,
  Coffee,
  ClipboardList,
  Gamepad2,
  Settings,
  UserCog,
  Palette,
  Bell,
  Monitor,
  HelpCircle,
  Wrench,
} from 'lucide-react'
import { type SidebarData } from '../types'

export const sidebarData: SidebarData = {
  user: {
    name: 'Admin',
    email: 'admin@chillax.cafe',
    avatar: '/avatars/shadcn.jpg',
  },
  teams: [
    {
      name: 'Chillax Cafe',
      logo: Coffee,
      plan: 'Admin Panel',
    },
  ],
  navGroups: [
    {
      title: 'Cafe Management',
      items: [
        {
          title: 'Dashboard',
          url: '/',
          icon: LayoutDashboard,
        },
        {
          title: 'Menu',
          url: '/menu',
          icon: Coffee,
        },
        {
          title: 'Orders',
          url: '/orders',
          icon: ClipboardList,
        },
        {
          title: 'PS Rooms',
          url: '/rooms',
          icon: Gamepad2,
        },
      ],
    },
    {
      title: 'Settings',
      items: [
        {
          title: 'Settings',
          icon: Settings,
          items: [
            {
              title: 'Profile',
              url: '/settings',
              icon: UserCog,
            },
            {
              title: 'Account',
              url: '/settings/account',
              icon: Wrench,
            },
            {
              title: 'Appearance',
              url: '/settings/appearance',
              icon: Palette,
            },
            {
              title: 'Notifications',
              url: '/settings/notifications',
              icon: Bell,
            },
            {
              title: 'Display',
              url: '/settings/display',
              icon: Monitor,
            },
          ],
        },
        {
          title: 'Help Center',
          url: '/help-center',
          icon: HelpCircle,
        },
      ],
    },
  ],
}
