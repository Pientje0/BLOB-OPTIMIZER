# ============================================================================
#  BLOB OPTIMIZER - GuiXaml.ps1
#  WPF markup for the window interface. WPF ships with Windows / .NET, so
#  nothing is downloaded or installed. Pure ASCII: glyphs use XML entities.
# ============================================================================

# Shared theme: merged into the main window and every dialog.
$Blob.GuiTheme = @'
<ResourceDictionary xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
                    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
  <SolidColorBrush x:Key="Bg" Color="#0B0F14"/>
  <SolidColorBrush x:Key="Panel" Color="#10161E"/>
  <SolidColorBrush x:Key="Card" Color="#151D27"/>
  <SolidColorBrush x:Key="CardHover" Color="#1A2431"/>
  <SolidColorBrush x:Key="Line" Color="#243244"/>
  <SolidColorBrush x:Key="Accent" Color="#22D3EE"/>
  <SolidColorBrush x:Key="AccentDim" Color="#0E7490"/>
  <SolidColorBrush x:Key="Text" Color="#E6EDF3"/>
  <SolidColorBrush x:Key="Sub" Color="#94A3B8"/>
  <SolidColorBrush x:Key="Muted" Color="#64748B"/>
  <SolidColorBrush x:Key="Good" Color="#4ADE80"/>
  <SolidColorBrush x:Key="Warn" Color="#FACC15"/>
  <SolidColorBrush x:Key="Bad" Color="#F87171"/>

  <Style TargetType="TextBlock">
    <Setter Property="Foreground" Value="{StaticResource Text}"/>
    <Setter Property="FontFamily" Value="Segoe UI"/>
    <Setter Property="TextWrapping" Value="Wrap"/>
  </Style>

  <Style TargetType="Button">
    <Setter Property="Foreground" Value="{StaticResource Text}"/>
    <Setter Property="Background" Value="{StaticResource Card}"/>
    <Setter Property="BorderBrush" Value="{StaticResource Line}"/>
    <Setter Property="Padding" Value="14,7"/>
    <Setter Property="Margin" Value="0,0,8,0"/>
    <Setter Property="FontFamily" Value="Segoe UI"/>
    <Setter Property="FontSize" Value="13"/>
    <Setter Property="Cursor" Value="Hand"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="Button">
          <Border x:Name="Bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
                  BorderThickness="1" CornerRadius="6" Padding="{TemplateBinding Padding}">
            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
          </Border>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="BorderBrush" Value="{StaticResource Accent}"/></Trigger>
            <Trigger Property="IsPressed" Value="True"><Setter TargetName="Bd" Property="Background" Value="{StaticResource AccentDim}"/></Trigger>
            <Trigger Property="IsEnabled" Value="False"><Setter TargetName="Bd" Property="Opacity" Value="0.4"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>
  <Style x:Key="AccentButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
    <Setter Property="Background" Value="{StaticResource Accent}"/>
    <Setter Property="BorderBrush" Value="{StaticResource Accent}"/>
    <Setter Property="Foreground" Value="#03141A"/>
    <Setter Property="FontWeight" Value="SemiBold"/>
  </Style>
  <Style x:Key="DangerButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
    <Setter Property="Foreground" Value="{StaticResource Bad}"/>
    <Setter Property="BorderBrush" Value="#7F1D1D"/>
  </Style>
  <Style x:Key="NavButton" TargetType="Button">
    <Setter Property="Foreground" Value="{StaticResource Sub}"/>
    <Setter Property="Background" Value="Transparent"/>
    <Setter Property="FontFamily" Value="Segoe UI"/>
    <Setter Property="FontSize" Value="14"/>
    <Setter Property="Cursor" Value="Hand"/>
    <Setter Property="HorizontalContentAlignment" Value="Left"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="Button">
          <Border x:Name="Bd" Background="{TemplateBinding Background}" CornerRadius="6" Margin="10,1" Padding="14,7">
            <ContentPresenter HorizontalAlignment="Left" VerticalAlignment="Center"/>
          </Border>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#16202B"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>
  <Style x:Key="CaptionButton" TargetType="Button">
    <Setter Property="Foreground" Value="{StaticResource Sub}"/>
    <Setter Property="Background" Value="Transparent"/>
    <Setter Property="Width" Value="46"/>
    <Setter Property="FontFamily" Value="Segoe MDL2 Assets"/>
    <Setter Property="FontSize" Value="10"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="Button">
          <Border x:Name="Bd" Background="{TemplateBinding Background}">
            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
          </Border>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#1F2937"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>

  <Style TargetType="CheckBox">
    <Setter Property="Foreground" Value="{StaticResource Text}"/>
    <Setter Property="Cursor" Value="Hand"/>
    <Setter Property="VerticalContentAlignment" Value="Top"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="CheckBox">
          <Grid Background="Transparent">
            <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <Border x:Name="Box" Width="18" Height="18" CornerRadius="4" Background="#0F172A" BorderBrush="#334155"
                    BorderThickness="1.5" VerticalAlignment="Top" Margin="0,2,10,0">
              <Path x:Name="Mark" Data="M3,8 L7,12 L14,4" Stroke="#03141A" StrokeThickness="2.2" Visibility="Collapsed"/>
            </Border>
            <ContentPresenter Grid.Column="1" VerticalAlignment="Top"/>
          </Grid>
          <ControlTemplate.Triggers>
            <Trigger Property="IsChecked" Value="True">
              <Setter TargetName="Box" Property="Background" Value="{StaticResource Accent}"/>
              <Setter TargetName="Box" Property="BorderBrush" Value="{StaticResource Accent}"/>
              <Setter TargetName="Mark" Property="Visibility" Value="Visible"/>
            </Trigger>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Box" Property="BorderBrush" Value="{StaticResource Accent}"/></Trigger>
            <Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.45"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>

  <Style TargetType="ScrollBar">
    <Setter Property="Width" Value="10"/>
    <Setter Property="MinWidth" Value="10"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="ScrollBar">
          <Track x:Name="PART_Track" IsDirectionReversed="True">
            <Track.Thumb><Thumb><Thumb.Template><ControlTemplate TargetType="Thumb">
              <Border CornerRadius="4" Background="#2A3A4E" Margin="2"/>
            </ControlTemplate></Thumb.Template></Thumb></Track.Thumb>
          </Track>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
    <Style.Triggers>
      <Trigger Property="Orientation" Value="Horizontal">
        <Setter Property="Width" Value="Auto"/>
        <Setter Property="Height" Value="10"/>
        <Setter Property="MinHeight" Value="10"/>
        <Setter Property="Template">
          <Setter.Value>
            <ControlTemplate TargetType="ScrollBar">
              <Track x:Name="PART_Track">
                <Track.Thumb><Thumb><Thumb.Template><ControlTemplate TargetType="Thumb">
                  <Border CornerRadius="4" Background="#2A3A4E" Margin="2"/>
                </ControlTemplate></Thumb.Template></Thumb></Track.Thumb>
              </Track>
            </ControlTemplate>
          </Setter.Value>
        </Setter>
      </Trigger>
    </Style.Triggers>
  </Style>

  <Style TargetType="TextBox">
    <Setter Property="Background" Value="#0F172A"/>
    <Setter Property="Foreground" Value="{StaticResource Text}"/>
    <Setter Property="BorderBrush" Value="#334155"/>
    <Setter Property="CaretBrush" Value="{StaticResource Accent}"/>
    <Setter Property="Padding" Value="8,6"/>
    <Setter Property="FontSize" Value="13"/>
  </Style>

  <Style TargetType="ComboBox">
    <Setter Property="Foreground" Value="{StaticResource Text}"/>
    <Setter Property="FontSize" Value="13"/>
    <Setter Property="MinWidth" Value="180"/>
    <Setter Property="Height" Value="34"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="ComboBox">
          <Grid>
            <ToggleButton Focusable="False" ClickMode="Press"
                          IsChecked="{Binding IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}">
              <ToggleButton.Template>
                <ControlTemplate TargetType="ToggleButton">
                  <Border x:Name="Bd" Background="#0F172A" BorderBrush="#334155" BorderThickness="1" CornerRadius="6">
                    <Path HorizontalAlignment="Right" VerticalAlignment="Center" Margin="0,0,12,0" Data="M0,0 L4,4 L8,0"
                          Stroke="#94A3B8" StrokeThickness="1.6"/>
                  </Border>
                  <ControlTemplate.Triggers>
                    <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="BorderBrush" Value="#22D3EE"/></Trigger>
                  </ControlTemplate.Triggers>
                </ControlTemplate>
              </ToggleButton.Template>
            </ToggleButton>
            <ContentPresenter IsHitTestVisible="False" Margin="10,0,30,0" VerticalAlignment="Center"
                              Content="{TemplateBinding SelectionBoxItem}" ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}"/>
            <Popup IsOpen="{TemplateBinding IsDropDownOpen}" Placement="Bottom" AllowsTransparency="True" Focusable="False">
              <Border Background="#111821" BorderBrush="#334155" BorderThickness="1" CornerRadius="6" Margin="0,2,0,0"
                      MinWidth="{TemplateBinding ActualWidth}" MaxHeight="320">
                <ScrollViewer><ItemsPresenter/></ScrollViewer>
              </Border>
            </Popup>
          </Grid>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>
  <Style TargetType="ComboBoxItem">
    <Setter Property="Foreground" Value="{StaticResource Text}"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="ComboBoxItem">
          <Border x:Name="Bd" Padding="10,6" Background="Transparent"><ContentPresenter/></Border>
          <ControlTemplate.Triggers>
            <Trigger Property="IsHighlighted" Value="True"><Setter TargetName="Bd" Property="Background" Value="#1E293B"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>

  <Style TargetType="ListBox">
    <Setter Property="Background" Value="Transparent"/>
    <Setter Property="BorderThickness" Value="0"/>
    <Setter Property="Foreground" Value="{StaticResource Text}"/>
  </Style>
  <Style TargetType="ListBoxItem">
    <Setter Property="Foreground" Value="{StaticResource Text}"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="ListBoxItem">
          <Border x:Name="Bd" Padding="12,8" Margin="0,1" CornerRadius="6" Background="{StaticResource Card}" BorderBrush="Transparent" BorderThickness="1">
            <ContentPresenter/>
          </Border>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="{StaticResource CardHover}"/></Trigger>
            <Trigger Property="IsSelected" Value="True"><Setter TargetName="Bd" Property="BorderBrush" Value="{StaticResource Accent}"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>

  <Style TargetType="DataGrid">
    <Setter Property="Background" Value="{StaticResource Panel}"/>
    <Setter Property="Foreground" Value="{StaticResource Text}"/>
    <Setter Property="BorderBrush" Value="{StaticResource Line}"/>
    <Setter Property="RowBackground" Value="Transparent"/>
    <Setter Property="AlternatingRowBackground" Value="#0E141B"/>
    <Setter Property="GridLinesVisibility" Value="None"/>
    <Setter Property="HeadersVisibility" Value="Column"/>
    <Setter Property="AutoGenerateColumns" Value="False"/>
    <Setter Property="IsReadOnly" Value="True"/>
    <Setter Property="CanUserAddRows" Value="False"/>
    <Setter Property="SelectionMode" Value="Extended"/>
    <Setter Property="SelectionUnit" Value="FullRow"/>
    <Setter Property="RowHeight" Value="30"/>
    <Setter Property="FontSize" Value="13"/>
  </Style>
  <Style TargetType="DataGridColumnHeader">
    <Setter Property="Background" Value="#111821"/>
    <Setter Property="Foreground" Value="{StaticResource Sub}"/>
    <Setter Property="Padding" Value="10,7"/>
    <Setter Property="BorderBrush" Value="{StaticResource Line}"/>
    <Setter Property="BorderThickness" Value="0,0,0,1"/>
    <Setter Property="FontWeight" Value="SemiBold"/>
  </Style>
  <Style TargetType="DataGridCell">
    <Setter Property="BorderThickness" Value="0"/>
    <Setter Property="Padding" Value="10,0"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="DataGridCell">
          <Border Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}">
            <ContentPresenter VerticalAlignment="Center"/>
          </Border>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
    <Style.Triggers>
      <Trigger Property="IsSelected" Value="True">
        <Setter Property="Background" Value="#123A47"/>
        <Setter Property="Foreground" Value="White"/>
      </Trigger>
    </Style.Triggers>
  </Style>

  <Style TargetType="ProgressBar">
    <Setter Property="Height" Value="8"/>
    <Setter Property="Foreground" Value="{StaticResource Accent}"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="ProgressBar">
          <Grid>
            <Border x:Name="PART_Track" Background="#1E293B" CornerRadius="4"/>
            <Border x:Name="PART_Indicator" HorizontalAlignment="Left" Background="{TemplateBinding Foreground}" CornerRadius="4"/>
          </Grid>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>

  <Style TargetType="ToolTip">
    <Setter Property="Foreground" Value="{StaticResource Text}"/>
    <Setter Property="HasDropShadow" Value="True"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="ToolTip">
          <Border Background="#121A24" BorderBrush="#2B6F80" BorderThickness="1" CornerRadius="8" Padding="14,12" MaxWidth="520">
            <ContentPresenter/>
          </Border>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>
</ResourceDictionary>
'@

$Blob.GuiXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="BLOB OPTIMIZER" Width="1220" Height="800" MinWidth="980" MinHeight="620"
        WindowStartupLocation="CenterScreen" Background="#0B0F14" WindowStyle="None" ResizeMode="CanResize"
        FontFamily="Segoe UI" UseLayoutRounding="True" TextOptions.TextFormattingMode="Display">
  <WindowChrome.WindowChrome>
    <WindowChrome CaptionHeight="46" ResizeBorderThickness="6" GlassFrameThickness="0" CornerRadius="0"/>
  </WindowChrome.WindowChrome>
  <!--THEME-->
  <Border x:Name="RootBorder" BorderBrush="#1C2733" BorderThickness="1">
    <Grid>
      <Grid.RowDefinitions>
        <RowDefinition Height="46"/>
        <RowDefinition Height="*"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="28"/>
      </Grid.RowDefinitions>

      <!-- Title bar -->
      <Grid Grid.Row="0" Background="#0B0F14">
        <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="18,0,0,0">
          <Border Width="22" Height="22" CornerRadius="11" Background="#22D3EE" Margin="0,0,10,0">
            <Border Width="10" Height="10" CornerRadius="5" Background="#0B0F14" Margin="6,0,0,6"/>
          </Border>
          <TextBlock Text="BLOB OPTIMIZER" FontWeight="Bold" FontSize="14" VerticalAlignment="Center"/>
          <TextBlock x:Name="TitleVersion" Foreground="#64748B" FontSize="12" Margin="10,0,0,0" VerticalAlignment="Center"/>
          <Border x:Name="AdminBadge" CornerRadius="4" Padding="8,2" Margin="14,0,0,0" VerticalAlignment="Center">
            <TextBlock x:Name="AdminBadgeText" FontSize="11" FontWeight="SemiBold"/>
          </Border>
          <Border x:Name="DryRunBadge" CornerRadius="4" Padding="8,2" Margin="8,0,0,0" Background="#3B0A45" VerticalAlignment="Center" Visibility="Collapsed">
            <TextBlock Text="DRY RUN" FontSize="11" FontWeight="SemiBold" Foreground="#E879F9"/>
          </Border>
        </StackPanel>
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
          <Button x:Name="BtnMin" Style="{StaticResource CaptionButton}" Content="&#xE921;" WindowChrome.IsHitTestVisibleInChrome="True" ToolTip="Minimize"/>
          <Button x:Name="BtnMax" Style="{StaticResource CaptionButton}" Content="&#xE922;" WindowChrome.IsHitTestVisibleInChrome="True" ToolTip="Maximize"/>
          <Button x:Name="BtnClose" Style="{StaticResource CaptionButton}" Content="&#xE8BB;" WindowChrome.IsHitTestVisibleInChrome="True" ToolTip="Close"/>
        </StackPanel>
      </Grid>

      <!-- Main area -->
      <Grid Grid.Row="1">
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="232"/>
          <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <Border Grid.Column="0" Background="#0D1218" BorderBrush="#1C2733" BorderThickness="0,1,1,0">
          <DockPanel>
            <StackPanel DockPanel.Dock="Top" Margin="26,16,20,12">
              <TextBlock Text="BLOB" FontSize="34" FontWeight="Black" Foreground="#22D3EE" Margin="0,0,0,-8"/>
              <TextBlock Text="O P T I M I Z E R" FontSize="12" FontWeight="SemiBold" Foreground="#94A3B8"/>
            </StackPanel>
            <StackPanel DockPanel.Dock="Bottom" Margin="26,6,20,12">
              <TextBlock x:Name="SideHost" Foreground="#64748B" FontSize="11"/>
              <TextBlock Text="No installation &#x00B7; nothing left running" Foreground="#475569" FontSize="11" Margin="0,2,0,0"/>
            </StackPanel>
            <ScrollViewer VerticalScrollBarVisibility="Auto">
              <StackPanel x:Name="NavPanel"/>
            </ScrollViewer>
          </DockPanel>
        </Border>

        <Grid Grid.Column="1" Background="#0B0F14">
          <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
          </Grid.RowDefinitions>
          <Border Grid.Row="0" BorderBrush="#1C2733" BorderThickness="0,1,0,1" Padding="30,18,24,16">
            <DockPanel>
              <StackPanel x:Name="PageActions" DockPanel.Dock="Right" Orientation="Horizontal" VerticalAlignment="Center"/>
              <StackPanel>
                <TextBlock x:Name="PageTitle" FontSize="24" FontWeight="SemiBold"/>
                <TextBlock x:Name="PageSubtitle" FontSize="13" Foreground="#94A3B8" Margin="0,4,0,0"/>
              </StackPanel>
            </DockPanel>
          </Border>
          <ScrollViewer x:Name="PageScroll" Grid.Row="1" VerticalScrollBarVisibility="Auto" Padding="30,20,24,24">
            <ContentControl x:Name="PageHost"/>
          </ScrollViewer>
        </Grid>
      </Grid>

      <!-- Activity log -->
      <Border Grid.Row="2" Background="#0D1218" BorderBrush="#1C2733" BorderThickness="0,1,0,0">
        <DockPanel>
          <DockPanel DockPanel.Dock="Top" Margin="18,8,12,4">
            <Button x:Name="BtnToggleLog" DockPanel.Dock="Right" Content="Hide" Padding="10,3" Margin="0" FontSize="11"/>
            <Button x:Name="BtnClearLog" DockPanel.Dock="Right" Content="Clear" Padding="10,3" FontSize="11"/>
            <TextBlock Text="ACTIVITY" FontSize="11" FontWeight="Bold" Foreground="#64748B" VerticalAlignment="Center"/>
          </DockPanel>
          <ScrollViewer x:Name="LogScroll" Height="92" VerticalScrollBarVisibility="Auto" Padding="18,0,12,8">
            <StackPanel x:Name="LogPanel"/>
          </ScrollViewer>
        </DockPanel>
      </Border>

      <!-- Status bar -->
      <Border Grid.Row="3" Background="#080B0F" BorderBrush="#1C2733" BorderThickness="0,1,0,0">
        <DockPanel Margin="18,0">
          <TextBlock x:Name="StatusRight" DockPanel.Dock="Right" Foreground="#475569" FontSize="11" VerticalAlignment="Center"/>
          <TextBlock x:Name="StatusText" Foreground="#94A3B8" FontSize="11" VerticalAlignment="Center" Text="Ready"/>
        </DockPanel>
      </Border>
    </Grid>
  </Border>
</Window>
'@

$Blob.GuiDialogXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Width="720" Height="560" MinWidth="520" MinHeight="320" WindowStyle="None" ResizeMode="CanResize"
        WindowStartupLocation="CenterOwner" Background="#10161E" ShowInTaskbar="False" FontFamily="Segoe UI">
  <WindowChrome.WindowChrome>
    <WindowChrome CaptionHeight="56" ResizeBorderThickness="6" GlassFrameThickness="0" CornerRadius="0"/>
  </WindowChrome.WindowChrome>
  <!--THEME-->
  <Border x:Name="DlgBorder" BorderBrush="#22D3EE" BorderThickness="1">
    <DockPanel>
      <Border DockPanel.Dock="Top" Padding="24,16,24,12" BorderBrush="#1C2733" BorderThickness="0,0,0,1">
        <StackPanel>
          <TextBlock x:Name="DlgTitle" FontSize="18" FontWeight="SemiBold"/>
          <TextBlock x:Name="DlgSub" FontSize="12" Foreground="#94A3B8" Margin="0,4,0,0"/>
        </StackPanel>
      </Border>
      <Border DockPanel.Dock="Bottom" Padding="24,12" BorderBrush="#1C2733" BorderThickness="0,1,0,0" Background="#0D1218">
        <DockPanel>
          <StackPanel DockPanel.Dock="Right" Orientation="Horizontal">
            <Button x:Name="DlgCancel" Content="Cancel" MinWidth="96"/>
            <Button x:Name="DlgOk" Content="Confirm" MinWidth="120" Margin="0" Style="{StaticResource AccentButton}"/>
          </StackPanel>
          <CheckBox x:Name="DlgCheck" VerticalAlignment="Center" Margin="0,0,16,0" Visibility="Collapsed">
            <TextBlock x:Name="DlgCheckText" FontSize="13"/>
          </CheckBox>
        </DockPanel>
      </Border>
      <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="24,14">
        <StackPanel x:Name="DlgBody"/>
      </ScrollViewer>
    </DockPanel>
  </Border>
</Window>
'@
