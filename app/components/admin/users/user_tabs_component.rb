# frozen_string_literal: true

module Admin
  module Users
    class UserTabsComponent < ViewComponent::Base
      def initialize(active_tab: 'personal')
        @active_tab = active_tab
      end

      private

      attr_reader :active_tab

      def tabs
        [
          { id: 'personal', label: 'Infos', icon: '👤' },
          { id: 'membership', label: 'Adhésion', icon: '🎪' },
          { id: 'payments', label: 'Paiements', icon: '💳' }
        ]
      end

      def tab_class(_tab_id)
        base_class = 'tab-button flex-1 py-3 px-2 text-center border-b-2 font-medium text-xs sm:text-sm'
        "#{base_class} border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
      end
    end
  end
end
