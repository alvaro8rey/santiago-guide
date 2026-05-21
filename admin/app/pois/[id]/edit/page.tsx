'use client';

import { useState, useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import { supabase } from '@/lib/supabase';
import { POIForm } from '@/app/components/poi-form';
import { POIFormData, POI } from '@/lib/types';

export default function EditPOIPage() {
  const router = useRouter();
  const params = useParams();
  const [poi, setPoi] = useState<POI | null>(null);
  const [loading, setLoading] = useState(true);
  const [saveLoading, setSaveLoading] = useState(false);

  const id = params.id as string;

  useEffect(() => {
    const fetchPoi = async () => {
      try {
        const { data, error } = await supabase
          .from('pois')
          .select('*')
          .eq('id', id)
          .single();

        if (error) throw error;
        setPoi(data);
      } catch (err) {
        console.error('Error fetching POI:', err);
        router.push('/');
      } finally {
        setLoading(false);
      }
    };

    fetchPoi();
  }, [id, router]);

  const handleSubmit = async (data: POIFormData) => {
    setSaveLoading(true);
    try {
      const { error } = await supabase
        .from('pois')
        .update({
          nombre: data.nombre,
          descripcion: data.descripcion,
          lat: data.lat,
          lng: data.lng,
          radio_activacion: data.radio_activacion,
          imagen_url: data.imagen_url,
          audio_url: data.audio_url,
          activo: data.activo,
          updated_at: new Date().toISOString(),
        })
        .eq('id', id);

      if (error) throw error;

      router.push('/');
    } catch (err) {
      console.error('Error updating POI:', err);
      throw err;
    } finally {
      setSaveLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-8">Editar POI</h1>
        <div className="bg-white rounded-lg shadow p-8">
          {poi && <POIForm poi={poi} onSubmit={handleSubmit} isLoading={saveLoading} />}
        </div>
      </div>
    </div>
  );
}
