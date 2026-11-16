// Generated from the database schema. Regenerate with: npm run db:types

export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];

export type Database = {
  public: {
    Tables: {
      channel_reads: {
        Row: {
          channel_id: string;
          last_read_at: string;
          user_id: string;
        };
        ComputedFields: never;
        Insert: {
          channel_id: string;
          last_read_at?: string;
          user_id: string;
        };
        Update: {
          channel_id?: string;
          last_read_at?: string;
          user_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: "channel_reads_channel_id_fkey";
            columns: ["channel_id"];
            isOneToOne: false;
            referencedRelation: "channels";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "channel_reads_user_id_fkey";
            columns: ["user_id"];
            isOneToOne: false;
            referencedRelation: "profiles";
            referencedColumns: ["id"];
          },
        ];
      };
      channels: {
        Row: {
          created_at: string;
          description: string | null;
          id: string;
          is_client_visible: boolean | null;
          name: string;
          project_id: string;
          slug: string;
          sort_order: number;
          visible_roles: Database["public"]["Enums"]["project_role"][];
        };
        ComputedFields: never;
        Insert: {
          created_at?: string;
          description?: string | null;
          id?: string;
          is_client_visible?: never;
          name: string;
          project_id: string;
          slug: string;
          sort_order?: number;
          visible_roles: Database["public"]["Enums"]["project_role"][];
        };
        Update: {
          created_at?: string;
          description?: string | null;
          id?: string;
          is_client_visible?: never;
          name?: string;
          project_id?: string;
          slug?: string;
          sort_order?: number;
          visible_roles?: Database["public"]["Enums"]["project_role"][];
        };
        Relationships: [
          {
            foreignKeyName: "channels_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "projects";
            referencedColumns: ["id"];
          },
        ];
      };
      frame_comments: {
        Row: {
          author_id: string;
          body: string;
          created_at: string;
          frame_id: string;
          id: string;
          project_id: string;
        };
        ComputedFields: never;
        Insert: {
          author_id: string;
          body: string;
          created_at?: string;
          frame_id: string;
          id?: string;
          project_id: string;
        };
        Update: {
          author_id?: string;
          body?: string;
          created_at?: string;
          frame_id?: string;
          id?: string;
          project_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: "frame_comments_author_id_fkey";
            columns: ["author_id"];
            isOneToOne: false;
            referencedRelation: "profiles";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "frame_comments_frame_id_fkey";
            columns: ["frame_id"];
            isOneToOne: false;
            referencedRelation: "frames";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "frame_comments_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "projects";
            referencedColumns: ["id"];
          },
        ];
      };
      frames: {
        Row: {
          approved_at: string | null;
          approved_by: string | null;
          file_path: string;
          frame_code: string;
          id: string;
          is_favorite: boolean;
          preview_path: string | null;
          project_id: string;
          sent_at: string;
          sent_by: string;
          shot_id: string | null;
          status: Database["public"]["Enums"]["frame_status"];
        };
        ComputedFields: never;
        Insert: {
          approved_at?: string | null;
          approved_by?: string | null;
          file_path: string;
          frame_code: string;
          id?: string;
          is_favorite?: boolean;
          preview_path?: string | null;
          project_id: string;
          sent_at?: string;
          sent_by: string;
          shot_id?: string | null;
          status?: Database["public"]["Enums"]["frame_status"];
        };
        Update: {
          approved_at?: string | null;
          approved_by?: string | null;
          file_path?: string;
          frame_code?: string;
          id?: string;
          is_favorite?: boolean;
          preview_path?: string | null;
          project_id?: string;
          sent_at?: string;
          sent_by?: string;
          shot_id?: string | null;
          status?: Database["public"]["Enums"]["frame_status"];
        };
        Relationships: [
          {
            foreignKeyName: "frames_approved_by_fkey";
            columns: ["approved_by"];
            isOneToOne: false;
            referencedRelation: "profiles";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "frames_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "projects";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "frames_sent_by_fkey";
            columns: ["sent_by"];
            isOneToOne: false;
            referencedRelation: "profiles";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "frames_shot_id_fkey";
            columns: ["shot_id"];
            isOneToOne: false;
            referencedRelation: "shots";
            referencedColumns: ["id"];
          },
        ];
      };
      messages: {
        Row: {
          attachment_name: string | null;
          attachment_path: string | null;
          attachment_preview_path: string | null;
          attachment_type: Database["public"]["Enums"]["attachment_kind"] | null;
          body: string | null;
          channel_id: string;
          created_at: string;
          frame_id: string | null;
          id: string;
          is_system: boolean;
          project_id: string;
          sender_id: string | null;
        };
        ComputedFields: never;
        Insert: {
          attachment_name?: string | null;
          attachment_path?: string | null;
          attachment_preview_path?: string | null;
          attachment_type?: Database["public"]["Enums"]["attachment_kind"] | null;
          body?: string | null;
          channel_id: string;
          created_at?: string;
          frame_id?: string | null;
          id?: string;
          is_system?: boolean;
          project_id: string;
          sender_id?: string | null;
        };
        Update: {
          attachment_name?: string | null;
          attachment_path?: string | null;
          attachment_preview_path?: string | null;
          attachment_type?: Database["public"]["Enums"]["attachment_kind"] | null;
          body?: string | null;
          channel_id?: string;
          created_at?: string;
          frame_id?: string | null;
          id?: string;
          is_system?: boolean;
          project_id?: string;
          sender_id?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: "messages_channel_id_project_id_fkey";
            columns: ["channel_id", "project_id"];
            isOneToOne: false;
            referencedRelation: "channels";
            referencedColumns: ["id", "project_id"];
          },
          {
            foreignKeyName: "messages_frame_id_fkey";
            columns: ["frame_id"];
            isOneToOne: false;
            referencedRelation: "frames";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "messages_sender_id_fkey";
            columns: ["sender_id"];
            isOneToOne: false;
            referencedRelation: "profiles";
            referencedColumns: ["id"];
          },
        ];
      };
      profiles: {
        Row: {
          avatar_path: string | null;
          created_at: string;
          full_name: string;
          id: string;
          phone: string | null;
        };
        ComputedFields: never;
        Insert: {
          avatar_path?: string | null;
          created_at?: string;
          full_name?: string;
          id: string;
          phone?: string | null;
        };
        Update: {
          avatar_path?: string | null;
          created_at?: string;
          full_name?: string;
          id?: string;
          phone?: string | null;
        };
        Relationships: [];
      };
      project_invites: {
        Row: {
          code: string;
          created_at: string;
          created_by: string;
          expires_at: string | null;
          project_id: string;
          revoked_at: string | null;
          role: Database["public"]["Enums"]["project_role"];
        };
        ComputedFields: never;
        Insert: {
          code: string;
          created_at?: string;
          created_by: string;
          expires_at?: string | null;
          project_id: string;
          revoked_at?: string | null;
          role: Database["public"]["Enums"]["project_role"];
        };
        Update: {
          code?: string;
          created_at?: string;
          created_by?: string;
          expires_at?: string | null;
          project_id?: string;
          revoked_at?: string | null;
          role?: Database["public"]["Enums"]["project_role"];
        };
        Relationships: [
          {
            foreignKeyName: "project_invites_created_by_fkey";
            columns: ["created_by"];
            isOneToOne: false;
            referencedRelation: "profiles";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "project_invites_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "projects";
            referencedColumns: ["id"];
          },
        ];
      };
      project_members: {
        Row: {
          department_title: string | null;
          joined_at: string;
          project_id: string;
          role: Database["public"]["Enums"]["project_role"];
          user_id: string;
        };
        ComputedFields: never;
        Insert: {
          department_title?: string | null;
          joined_at?: string;
          project_id: string;
          role: Database["public"]["Enums"]["project_role"];
          user_id: string;
        };
        Update: {
          department_title?: string | null;
          joined_at?: string;
          project_id?: string;
          role?: Database["public"]["Enums"]["project_role"];
          user_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: "project_members_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "projects";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "project_members_user_id_fkey";
            columns: ["user_id"];
            isOneToOne: false;
            referencedRelation: "profiles";
            referencedColumns: ["id"];
          },
        ];
      };
      projects: {
        Row: {
          created_at: string;
          created_by: string;
          crew_call: string | null;
          id: string;
          job: string | null;
          location: string | null;
          location_notes: string | null;
          name: string;
          recording_enabled: boolean;
          shoot_date: string | null;
          status: Database["public"]["Enums"]["project_status"];
          timezone: string;
          wrapped_at: string | null;
        };
        ComputedFields: never;
        Insert: {
          created_at?: string;
          created_by: string;
          crew_call?: string | null;
          id?: string;
          job?: string | null;
          location?: string | null;
          location_notes?: string | null;
          name: string;
          recording_enabled?: boolean;
          shoot_date?: string | null;
          status?: Database["public"]["Enums"]["project_status"];
          timezone?: string;
          wrapped_at?: string | null;
        };
        Update: {
          created_at?: string;
          created_by?: string;
          crew_call?: string | null;
          id?: string;
          job?: string | null;
          location?: string | null;
          location_notes?: string | null;
          name?: string;
          recording_enabled?: boolean;
          shoot_date?: string | null;
          status?: Database["public"]["Enums"]["project_status"];
          timezone?: string;
          wrapped_at?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: "projects_created_by_fkey";
            columns: ["created_by"];
            isOneToOne: false;
            referencedRelation: "profiles";
            referencedColumns: ["id"];
          },
        ];
      };
      ptt_channels: {
        Row: {
          allowed_roles: Database["public"]["Enums"]["project_role"][];
          created_at: string;
          id: string;
          livekit_room: string | null;
          name: string;
          project_id: string;
        };
        ComputedFields: never;
        Insert: {
          allowed_roles: Database["public"]["Enums"]["project_role"][];
          created_at?: string;
          id?: string;
          livekit_room?: never;
          name: string;
          project_id: string;
        };
        Update: {
          allowed_roles?: Database["public"]["Enums"]["project_role"][];
          created_at?: string;
          id?: string;
          livekit_room?: never;
          name?: string;
          project_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: "ptt_channels_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "projects";
            referencedColumns: ["id"];
          },
        ];
      };
      ptt_transmissions: {
        Row: {
          duration_ms: number;
          id: string;
          latency_ms: number | null;
          project_id: string;
          ptt_channel_id: string;
          recording_path: string | null;
          speaker_id: string;
          started_at: string;
          transcript: string | null;
        };
        ComputedFields: never;
        Insert: {
          duration_ms: number;
          id?: string;
          latency_ms?: number | null;
          project_id: string;
          ptt_channel_id: string;
          recording_path?: string | null;
          speaker_id: string;
          started_at: string;
          transcript?: string | null;
        };
        Update: {
          duration_ms?: number;
          id?: string;
          latency_ms?: number | null;
          project_id?: string;
          ptt_channel_id?: string;
          recording_path?: string | null;
          speaker_id?: string;
          started_at?: string;
          transcript?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: "ptt_transmissions_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "projects";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "ptt_transmissions_ptt_channel_id_fkey";
            columns: ["ptt_channel_id"];
            isOneToOne: false;
            referencedRelation: "ptt_channels";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "ptt_transmissions_speaker_id_fkey";
            columns: ["speaker_id"];
            isOneToOne: false;
            referencedRelation: "profiles";
            referencedColumns: ["id"];
          },
        ];
      };
      push_tokens: {
        Row: {
          platform: string;
          token: string;
          updated_at: string;
          user_id: string;
        };
        ComputedFields: never;
        Insert: {
          platform: string;
          token: string;
          updated_at?: string;
          user_id: string;
        };
        Update: {
          platform?: string;
          token?: string;
          updated_at?: string;
          user_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: "push_tokens_user_id_fkey";
            columns: ["user_id"];
            isOneToOne: false;
            referencedRelation: "profiles";
            referencedColumns: ["id"];
          },
        ];
      };
      schedule_items: {
        Row: {
          id: string;
          label: string;
          project_id: string;
          sort_order: number;
          time: string;
        };
        ComputedFields: never;
        Insert: {
          id?: string;
          label: string;
          project_id: string;
          sort_order?: number;
          time: string;
        };
        Update: {
          id?: string;
          label?: string;
          project_id?: string;
          sort_order?: number;
          time?: string;
        };
        Relationships: [
          {
            foreignKeyName: "schedule_items_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "projects";
            referencedColumns: ["id"];
          },
        ];
      };
      shots: {
        Row: {
          approved_frame_id: string | null;
          created_at: string;
          done_at: string | null;
          done_by: string | null;
          id: string;
          is_done: boolean;
          name: string;
          number: number;
          project_id: string;
          sort_order: number;
        };
        ComputedFields: never;
        Insert: {
          approved_frame_id?: string | null;
          created_at?: string;
          done_at?: string | null;
          done_by?: string | null;
          id?: string;
          is_done?: boolean;
          name: string;
          number: number;
          project_id: string;
          sort_order?: number;
        };
        Update: {
          approved_frame_id?: string | null;
          created_at?: string;
          done_at?: string | null;
          done_by?: string | null;
          id?: string;
          is_done?: boolean;
          name?: string;
          number?: number;
          project_id?: string;
          sort_order?: number;
        };
        Relationships: [
          {
            foreignKeyName: "shots_approved_frame_fk";
            columns: ["approved_frame_id"];
            isOneToOne: false;
            referencedRelation: "frames";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "shots_done_by_fkey";
            columns: ["done_by"];
            isOneToOne: false;
            referencedRelation: "profiles";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "shots_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "projects";
            referencedColumns: ["id"];
          },
        ];
      };
    };
    Views: {
      [_ in never]: never;
    };
    Functions: {
      approve_frame: {
        Args: { p_frame: string };
        Returns: {
          approved_at: string | null;
          approved_by: string | null;
          file_path: string;
          frame_code: string;
          id: string;
          is_favorite: boolean;
          preview_path: string | null;
          project_id: string;
          sent_at: string;
          sent_by: string;
          shot_id: string | null;
          status: Database["public"]["Enums"]["frame_status"];
        };
        SetofOptions: {
          from: "*";
          to: "frames";
          isOneToOne: true;
          isSetofReturn: false;
        };
      };
      can_see_channel: { Args: { p_channel: string }; Returns: boolean };
      can_use_ptt: { Args: { p_ptt: string }; Returns: boolean };
      create_invite: {
        Args: { p_project: string; p_role: Database["public"]["Enums"]["project_role"] };
        Returns: string;
      };
      create_project: {
        Args: {
          p_crew_call?: string;
          p_job?: string;
          p_location?: string;
          p_name: string;
          p_shoot_date?: string;
          p_timezone?: string;
        };
        Returns: string;
      };
      is_member: { Args: { p_project: string }; Returns: boolean };
      join_project: { Args: { p_code: string }; Returns: string };
      my_role: {
        Args: { p_project: string };
        Returns: Database["public"]["Enums"]["project_role"];
      };
      role_can: { Args: { p_perm: string; p_project: string }; Returns: boolean };
      send_frame: {
        Args: {
          p_file_path: string;
          p_frame_code: string;
          p_preview_path: string;
          p_project: string;
          p_shot: string;
        };
        Returns: {
          approved_at: string | null;
          approved_by: string | null;
          file_path: string;
          frame_code: string;
          id: string;
          is_favorite: boolean;
          preview_path: string | null;
          project_id: string;
          sent_at: string;
          sent_by: string;
          shot_id: string | null;
          status: Database["public"]["Enums"]["frame_status"];
        };
        SetofOptions: {
          from: "*";
          to: "frames";
          isOneToOne: true;
          isSetofReturn: false;
        };
      };
      set_wrapped: { Args: { p_project: string; p_wrapped: boolean }; Returns: undefined };
      shares_project_with: { Args: { p_user: string }; Returns: boolean };
      storage_can: { Args: { p_name: string; p_write: boolean }; Returns: boolean };
    };
    Enums: {
      attachment_kind: "image" | "video" | "file";
      frame_status: "pending" | "approved" | "alt";
      project_role:
        | "producer"
        | "photographer"
        | "digi_tech"
        | "crew"
        | "glam"
        | "agency"
        | "client"
        | "talent";
      project_status: "prep" | "live" | "wrapped";
    };
    CompositeTypes: {
      [_ in never]: never;
    };
  };
};

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">;

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">];

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R;
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] & DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R;
      }
      ? R
      : never
    : never;

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I;
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I;
      }
      ? I
      : never
    : never;

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U;
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U;
      }
      ? U
      : never
    : never;

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never;

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never;

export const Constants = {
  public: {
    Enums: {
      attachment_kind: ["image", "video", "file"],
      frame_status: ["pending", "approved", "alt"],
      project_role: [
        "producer",
        "photographer",
        "digi_tech",
        "crew",
        "glam",
        "agency",
        "client",
        "talent",
      ],
      project_status: ["prep", "live", "wrapped"],
    },
  },
} as const;
