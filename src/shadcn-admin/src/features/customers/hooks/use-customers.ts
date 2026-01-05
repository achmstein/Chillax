import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { customersApi, type GetCustomersParams } from '@/lib/api'

export const customersKeys = {
  all: ['customers'] as const,
  lists: () => [...customersKeys.all, 'list'] as const,
  list: (params: GetCustomersParams) => [...customersKeys.lists(), params] as const,
}

export function useCustomers(params: GetCustomersParams = {}) {
  return useQuery({
    queryKey: customersKeys.list(params),
    queryFn: () => customersApi.getCustomers(params),
  })
}

export function useBlockCustomer() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (customerId: string) => customersApi.blockCustomer(customerId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: customersKeys.lists() })
    },
  })
}

export function useUnblockCustomer() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (customerId: string) => customersApi.unblockCustomer(customerId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: customersKeys.lists() })
    },
  })
}
