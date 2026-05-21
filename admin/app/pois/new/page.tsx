'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase';
import { POIForm } from '@/app/components/poi-form';
import { POIFormData } from '@/lib/types';

export default function NewPOIPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (data: POIFormData) => {
    setLoading(true);
    try {
      const { error } = await supabase.from('pois').insert({
        nombre: data.nombre,
        descripcion: data.descripcion,
        lat: data.lat,
        lng: data.lng,
        radio_activacion: data.radio_activacion,
        imagen_url: data.imagen_url,
        audio_url: data.audio_url,
        activo: data.activo,
      });

      if (error) throw error;

      router.push('/');
    } catch (err) {
      console.error('Error creating POI:', err);
      throw err;
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-8">Crear nuevo POI</h1>
        <div className="bg-white rounded-lg shadow p-8">
          <POIForm onSubmit={handleSubmit} isLoading={loading} />
        </div>
      </div>
    </div>
  );
}
