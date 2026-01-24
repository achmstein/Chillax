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
  Tag,
  Users,
  Award,
  Wallet,
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
          icon: Coffee,
          items: [
            {
              title: 'Items',
              url: '/menu',
              icon: Coffee,
            },
            {
              title: 'Categories',
              url: '/menu/categories',
              icon: Tag,
            },
          ],
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
        {
          title: 'Customers',
          url: '/customers',
          icon: Users,
        },
        {
          title: 'Loyalty',
          url: '/loyalty',
          icon: Award,
        },
        {
          title: 'Accounts',
          url: '/accounts',
          icon: Wallet,
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
